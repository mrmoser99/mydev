/**
    Change Log:

    09/01/2022 - MRM Created  
*/
import { LightningElement,api ,wire} from 'lwc';
import getCustomerId from "@salesforce/apex/CustomerUtils.getCustomerId";
import getRelatedFilesByRecordId from '@salesforce/apex/EnrollController.getRelatedFilesByRecordId';
import getZipUrl from '@salesforce/apex/EnrollController.getZipUrl';
import getFundingDate from '@salesforce/apex/EnrollController.getFundingDate';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class EnrollCompleteFunding extends LightningElement {
    @api oppId; 
    customerId;
    objectName='Account';
    docType = 'Partner';
    refreshExecute=0;
    filesList2 = [];
    filesToShow2;
    refresh = false;
    provisionedValue;
    fundingDate;

    /***********************************************************************************************************
    * getCustomerId
    ************************************************************************************************************/
    @wire(getCustomerId,{ recordId: '$oppId', refreshExecute : '$refreshExecute'}) 
        wiredgetCustomerId({data, error}) {
         
            if (data) {
                 
                this.customerId = data;
                console.log('calling get date');
                getFundingDate({opportunityId: this.oppId})
                .then(result => {
                    console.log('result is d: ' + result);
        
                    this.fundingDate = result;
            
                })
                .catch(error => {
                    const evt = new ShowToastEvent({
                        title: 'Error',
                        message: 'Failure!' + JSON.stringify(error),
                        variant: 'error',
                        duration:5000,
                    });
                    this.dispatchEvent(evt);
                }) 
                
            } else if (error) {  
             
                this.customerId = null; 
                this.showToast('Something went wrong', error.body.message, 'error');
                this.loading=false;
                return;
            }
         
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'sticky'
        });
        this.dispatchEvent(event);
    }

    @wire(getRelatedFilesByRecordId, {refresh: '$refresh', recordId: '$oppId', docType: '$docType'})
    wiredResult(provisionedValue){ 
        this.provisionedValue = provisionedValue;
        const {data, error } = provisionedValue;

        console.log('*******************************' + this.docType);
        if(data){ 
            console.log('wire fired');
            this.filesList2 = Object.keys(data).map(item=>({
                "label":data[item],
                "value": item,
                "url":`/dllondemand/sfc/servlet.shepherd/document/download/${item}`,
            }))
            if (this.filesList2.length > 0)
                this.filesToShow2 = true;
            console.log(this.filesList2);
        }
        
        if(error){ 
            console.log(error)
        }
    }

    download(event){
        console.log('downloading...' + event.target.value) ;
        window.open(event.target.value,'_blank');
    }

    downloadPackage(event){

        console.log('downloading package....') ;

        getZipUrl ({recordId : this.oppId})
        .then(result => {
            console.log('result2 is: ' + result);
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