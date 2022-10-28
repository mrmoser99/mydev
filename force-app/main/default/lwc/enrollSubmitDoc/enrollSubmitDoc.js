/**
 * @description       : LWC component to display submit doc screen. 
 * @author            : Surbhi Goyal : Traction on Demand
 * @group             : Kritika Sharma & Surbhi Goyal :  Traction on Demand
 * @last modified on  : 05-06-2022
 * @last modified by  : Kritika Sharma
 * 
 * Change Log:
 * 
 * 08/29/2022 - MRM - Made the page upload and download documents.
**/
/*****************************************************************************************************
 * 
 * Change Log:
 * 
 * 07/21/2022 - MRM Added file list
 */
import { LightningElement,api,wire,track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
// Custom Labels
import getRelatedFilesByRecordId from '@salesforce/apex/EnrollController.getRelatedFilesByRecordId';
import deleteContentDocument from '@salesforce/apex/EnrollController.deleteContentDocument';
import getZipUrl from '@salesforce/apex/EnrollController.getZipUrl';
import { refreshApex } from '@salesforce/apex';

import SUBMIT_DOC_TITLE from '@salesforce/label/c.SUBMIT_DOC_TITLE';
import SUBMIT_DOC_TITLE_DESC from '@salesforce/label/c.SUBMIT_DOC_TITLE_DESC';
import DOWNLOAD_DOC_DLL from '@salesforce/label/c.DOWNLOAD_DOC_DLL';
import DOWNLOAD_DOC_DLL_DESC from '@salesforce/label/c.DOWNLOAD_DOC_DLL_DESC';
 

import UPLOAD_DOC from '@salesforce/label/c.UPLOAD_DOC';
import UPLOAD_DOC_DESC from '@salesforce/label/c.UPLOAD_DOC_DESC';
import UPLOADED_DOC from '@salesforce/label/c.UPLOADED_DOC';
import UPLOADED_DOCS_DESC from '@salesforce/label/c.UPLOADED_DOCS_DESC';

import DOWNLOAD_DOC_NO_FILES from '@salesforce/label/c.DOWNLOAD_DOC_NO_FILES';



export default class EnrollSubmitDoc extends NavigationMixin(LightningElement) {
    @api oppId;
    @api editMode;
    @api refresh = false;
    wiredData = [];
    wiredError = [];

    filesToShow=false;
    filesToShow2=false;
    deleteRecordId;
    @api isModalOpen = false;

    provisionedValue;

    @api docType = 'Sales Support';

     
    
    filesList = [];
    filesList2 = [];
    fileListPartner = [];
    label = {
        SUBMIT_DOC_TITLE,
        SUBMIT_DOC_TITLE_DESC,
        DOWNLOAD_DOC_DLL,
        DOWNLOAD_DOC_DLL_DESC,
        UPLOAD_DOC,
        UPLOAD_DOC_DESC,
        UPLOADED_DOC,
        UPLOADED_DOCS_DESC
    };
     
    //using same wired object for both sales support and partner doctype....pretty cool 

    @wire(getRelatedFilesByRecordId, {refresh: '$refresh', recordId: '$oppId', docType: '$docType'})
    wiredResult(provisionedValue){ 
        this.provisionedValue = provisionedValue;
        const {data, error } = provisionedValue;

        console.log('*******************************' + this.docType);
        if(data){ 
            console.log('wire fired');
            if (this.docType == 'Partner'){  //Partner
                this.filesList2 = Object.keys(data).map(item=>({
                "label":data[item],
                "value": item,
                "url":`/dllondemand/sfc/servlet.shepherd/document/download/${item}`,
                }))
                if (this.filesList2.length > 0)
                    this.filesToShow2 = true;
                console.log(this.filesList2);
            }
            else{  //Sales Support
                 this.docType = 'Partner';  //cause this wire to fire
                 this.filesList = Object.keys(data).map(item=>({"label":data[item],
                "value": item,
                "url":`/dllondemand/sfc/servlet.shepherd/document/download/${item}` 
                }))
                if (this.filesList.length > 0)
                    this.filesToShow = true;
                console.log(this.filesList);

            }
        }
        if(error){ 
            console.log(error)
        }

       
    }

    closeModal(event){
        this.isModalOpen = false;

    }

    refreshPage(event){

        refreshApex(this.provisionedValue);
        
    }



    deleteDocument(event){
    
        this.isModalOpen = false;
 
        this.isLoading = true;
         
        deleteContentDocument ({recordId : this.deleteRecordId})
        .then(result => {
            if (result == 'ok'){
                refreshApex(this.provisionedValue);
                const evt = new ShowToastEvent({
                    title: 'Succes',
                    message: 'The document has been successfully deleted!',
                    variant: 'success',
                    duration:5000,
                });
                this.dispatchEvent(evt);
                this.isLoading = false;
            }
            else{
                console.log('result is bad');
                const evt = new ShowToastEvent({
                    title: 'Error',
                    message: 'Failure!' + result,
                    variant: 'error',
                    duration:5000,
                });
                this.dispatchEvent(evt);
            }
            
        })
        .catch(error => {
            this.searchData = undefined;
            console.log('error =====> '+JSON.stringify(error));
            const evt = new ShowToastEvent({
                title: 'Error',
                message: 'Failure!' + error,
                variant: 'error',
                duration:5000,
                });
                this.dispatchEvent(evt);
        }) 

        
    }
   
    deleteDoc(event){
        var x = Number(event.currentTarget.id);
        this.deleteRecordId = this.filesList2[x].value;
        this.isModalOpen = true;
    }

    download(event){
        console.log('downloading...' + event.target.value) ;
        window.open(event.target.value,'_blank');
    }

    downloadPackage(event){

        console.log('downloading package...') ;

        getZipUrl ({recordId : this.oppId})
        .then(result => {
            console.log('result is: ' + result);
            if (result.includes('download?')){
                console.log('no files');
                const evt = new ShowToastEvent({
                title: 'Error',
                message: 'There are no files to download!',
                variant: 'error',
                duration:5000,
                });
                this.dispatchEvent(evt);
                return;
            }
            if (result != null){
                console.log('ok');
                console.log('ready to open' + result);
                window.open(result,'_blank');
                console.log('done');
                const evt = new ShowToastEvent({
                    title: 'Success',
                    message: 'The package has been downloaded!',
                    variant: 'success',
                    duration:5000,
                });
                this.dispatchEvent(evt);
            }
            else{
                console.log('result is bad');
                const evt = new ShowToastEvent({
                    title: 'Error',
                    message: 'Failure!' + JSON.stringify(error),
                    variant: 'error',
                    duration:5000,
                });
                this.dispatchEvent(evt);
            }
            
        })
        .catch(error => {
            this.searchData = undefined;
            console.log('error =====> '+JSON.stringify(error));
            const evt = new ShowToastEvent({
                title: 'Error',
                message: 'Failure!' + JSON.stringify(error),
                variant: 'error',
                duration:5000,
                });
                this.dispatchEvent(evt);
        }) 
        
        
    }
}