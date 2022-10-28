/**
 * @description       : LWC component to display Request Doc screen. 
 * @author            : Surbhi Goyal : Traction on Demand
 * @group             : Kritika Sharma & Surbhi Goyal :  Traction on Demand
 * @last modified on  : 09-06-2022
 * @last modified by  : Kritika Sharma
 * /**************************************************************************************
 * change log:
 * 
 * 07/19/2022 - MRM added toast message upon request docs click
 * 07/22/2022 - Added document list
 * 
 * ********************************************************************************* */

import { LightningElement , wire , api, track } from 'lwc';

import getContactField from '@salesforce/apex/EnrollController.getContactField';
import { deleteRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getReviewerField from '@salesforce/apex/EnrollController.getReviewerField';
import saveDocusignToOpp from '@salesforce/apex/EnrollController.saveDocusignToOpp';
import getDocusignValueFromOpp from '@salesforce/apex/EnrollController.getDocusignValueFromOpp';
import { refreshApex } from '@salesforce/apex';

//Custom Label
import ENROLL_REQ_DOC from '@salesforce/label/c.ENROLL_REQ_DOC';
import DOWNLOAD_DOC_NO_FILES from '@salesforce/label/c.DOWNLOAD_DOC_NO_FILES';
import ENROLL_REQ_DOC_CONTENT from '@salesforce/label/c.ENROLL_REQ_DOC_CONTENT';
import ENROLL_REQ_DOC_DELIVERY_PREFERENCE from '@salesforce/label/c.ENROLL_REQ_DOC_DELIVERY_PREFERENCE';
import ENROLL_REQ_DOC_SIGNER from '@salesforce/label/c.ENROLL_REQ_DOC_SIGNER';
import ENROLL_REQ_DOC_CONTENT1 from '@salesforce/label/c.ENROLL_REQ_DOC_CONTENT1';
import ENROLL_REQ_DOC_FIRST_NAME from '@salesforce/label/c.ENROLL_REQ_DOC_FIRST_NAME';
import ENROLL_REQ_DOC_MIDDLE from '@salesforce/label/c.ENROLL_REQ_DOC_MIDDLE';
import ENROLL_REQ_DOC_LAST_NAME from '@salesforce/label/c.ENROLL_REQ_DOC_LAST_NAME';
import ENROLL_REQ_DOC_SIGNERS_TITLE from '@salesforce/label/c.ENROLL_REQ_DOC_SIGNERS_TITLE';
import ENROLL_REQ_DOC_SIGNERS_EMAIL from '@salesforce/label/c.ENROLL_REQ_DOC_SIGNERS_EMAIL';
import ENROLL_REQ_DOC_DELETE from '@salesforce/label/c.ENROLL_REQ_DOC_DELETE';
import ENROLL_REQ_DOC_ADD from '@salesforce/label/c.ENROLL_REQ_DOC_ADD';
import ENROLL_REQ_DOC_REVIEWRS from '@salesforce/label/c.ENROLL_REQ_DOC_REVIEWRS';

import ENROLL_REQ_DOC_CONTENT2 from '@salesforce/label/c.ENROLL_REQ_DOC_CONTENT2';
import ENROLL_REQ_DOC_REVIERS_FIRST_NAME from '@salesforce/label/c.ENROLL_REQ_DOC_REVIERS_FIRST_NAME';
import ENROLL_REQ_DOC_REVIERS_LAST_NAME from '@salesforce/label/c.ENROLL_REQ_DOC_REVIERS_LAST_NAME';
import ENROLL_REQ_DOC_REVIERS_TITLE from '@salesforce/label/c.ENROLL_REQ_DOC_REVIERS_TITLE';
import ENROLL_REQ_DOC_REVIERS_EMAIL from '@salesforce/label/c.ENROLL_REQ_DOC_REVIERS_EMAIL';
import ENROLL_REQ_DOC_REVIERS_DELETE from '@salesforce/label/c.ENROLL_REQ_DOC_REVIERS_DELETE';
import ENROLL_REQ_DOC_REVIERS_ADD from '@salesforce/label/c.ENROLL_REQ_DOC_REVIERS_ADD';
import ENROLL_REQ_DOC_SEPERATE from '@salesforce/label/c.ENROLL_REQ_DOC_SEPERATE';
import ENROLL_REQ_DOC_CONTENT3 from '@salesforce/label/c.ENROLL_REQ_DOC_CONTENT3';
import ENROLL_REQ_DOC_ACCEPT_CHECK from '@salesforce/label/c.ENROLL_REQ_DOC_ACCEPT_CHECK';
import ENROLL_REQ_DOC_SIGNERS from '@salesforce/label/c.ENROLL_REQ_DOC_SIGNERS';
import ENROLL_REQ_DOC_SIGNERS_CONTENT from '@salesforce/label/c.ENROLL_REQ_DOC_SIGNERS_CONTENT';
import ENROLL_REQ_DOC_OPTION1 from '@salesforce/label/c.ENROLL_REQ_DOC_OPTION1';
import ENROLL_REQ_DOC_OPTION2 from '@salesforce/label/c.ENROLL_REQ_DOC_OPTION2';
import ENROL_REVIEW_REQUIRED from '@salesforce/label/c.ENROL_REVIEW_REQUIRED';


export default class EnrollRequestDoc extends LightningElement {

    label = {
        ENROLL_REQ_DOC,
        ENROLL_REQ_DOC_CONTENT,
        ENROLL_REQ_DOC_DELIVERY_PREFERENCE,
        ENROLL_REQ_DOC_SIGNER,
        ENROLL_REQ_DOC_CONTENT1,
        ENROLL_REQ_DOC_FIRST_NAME,
        ENROLL_REQ_DOC_MIDDLE,
        ENROLL_REQ_DOC_LAST_NAME,
        ENROLL_REQ_DOC_SIGNERS_TITLE,
        ENROLL_REQ_DOC_SIGNERS_EMAIL,
        ENROLL_REQ_DOC_DELETE,
        ENROLL_REQ_DOC_ADD,
        ENROLL_REQ_DOC_REVIEWRS,
        ENROLL_REQ_DOC_CONTENT2,
        ENROLL_REQ_DOC_REVIERS_FIRST_NAME,
        ENROLL_REQ_DOC_REVIERS_LAST_NAME,
        ENROLL_REQ_DOC_REVIERS_TITLE,
        ENROLL_REQ_DOC_REVIERS_EMAIL,
        ENROLL_REQ_DOC_REVIERS_DELETE,
        ENROLL_REQ_DOC_REVIERS_ADD,
        ENROLL_REQ_DOC_SEPERATE,
        ENROLL_REQ_DOC_CONTENT3,
        ENROLL_REQ_DOC_ACCEPT_CHECK,
        ENROLL_REQ_DOC_SIGNERS,
        ENROLL_REQ_DOC_SIGNERS_CONTENT,
        ENROLL_REQ_DOC_OPTION1,
        ENROLL_REQ_DOC_OPTION2,
        ENROL_REVIEW_REQUIRED
    }

    @api oppId;
    @api editMode;
    documentTypeOptions=[
        { label: ENROLL_REQ_DOC_OPTION1, value: 'option1' },
        { label: ENROLL_REQ_DOC_OPTION2, value: 'option2' },
    ];
    @track wiredRefreshList;
    filesList = [];
     

    documentTypeValue='option1';

    connectedCallback() {
        this.loading = true;
        getDocusignValueFromOpp({opportunityId : this.oppId})
            .then(result => {
                if (result === 'true') {
                    this.documentTypeValue = 'option1';
                } else {
                    this.documentTypeValue = 'option2';
                } 
                this.loading = false;
            }).catch(error => {
                this.loading = false;
                console.log('error loading docusign selection');
            });
    }

    // A counter to load contact roles
    contactRolesReloaded = 0;

    @track
    contactDetail=[];

    @track
    contactDetailOptionTwo=[];

    @track
    reviewDetail=[];

    @track
    docSignType=true;

    loading=false;
    addSignerFlag = false;
    isDetailsEmpty=false;

    @api
    get contactDetail(){
        return this.contactDetail;
    }
    
    @api
    get reviewDetail(){
        return this.reviewDetail;
    }

    @api
    get contactDetailOptionTwo(){
        return this.contactDetailOptionTwo;
    }

    @api
    get docusignType() {
        return this.docSignType;
    }
    
    // Wired method for Option One signers
    @wire(getContactField, {opportunityId: '$oppId', loadCount: '$contactRolesReloaded'})
    wiredGetContact({ error, data }){
        if (data) {
            //this.wiredRefreshList=data;
            var ownerLen=0;
            console.log(data.length);
            if(data.length < 1){
                ownerLen=1;
                this.contactDetail=[{
                    ownerHeading:'Signer '+ownerLen,
                    ownerNo:1,
                    firstName:'',
                    middleName:'',
                    lastName:'',
                    titleValue:'',
                    emailValue:''
                }]
            }
            console.log('data signers::'+data);
            for(var i=0;i<data.length;i++) {
                ownerLen=i+1;
                console.log(JSON.parse(JSON.stringify(data[i])));
                this.contactDetail.push({
                    ownerHeading:'Signer '+ownerLen,
                    ownerNo:ownerLen,
                    firstName:data[i].FirstName,
                    middleName:data[i].MiddleName,
                    lastName:data[i].LastName,
                    titleValue:data[i].Title,
                    emailValue:data[i].Email,
                    endUserAccount:data[i].AccountId,
                    Id:data[i].Id,
                    uboID:data[i].uboID
                });
            }
            console.log('this.contactDetail::::'+JSON.stringify(this.contactDetail));
        } else if (error) {
            console.log(JSON.parse(JSON.stringify(error)));
            this.contactDetail = [];
        } 
    } 

    //Wired method for Option One Reviewers
    @wire(getReviewerField, {opportunityId: '$oppId', loadCount: '$contactRolesReloaded'})
    wiredGetReview({ error, data }){
        if (data) {
            var ownerLen=0;
            console.log(data.length);
            if(data.length < 1){
                ownerLen=1;
                this.reviewDetail=[{
                    ownerHeading:'Reviewer '+ownerLen,
                    ownerNo:1,
                    firstName:'',
                    middleName:'',
                    lastName:'',
                    titleValue:'',
                    emailValue:''
                }]
            }
            for(var i=0;i<data.length;i++) {
                ownerLen=i+1;
                this.reviewDetail.push({
                    ownerHeading:'Reviewer '+ownerLen,
                    ownerNo:ownerLen,
                    firstName:data[i].FirstName,
                    middleName:data[i].MiddleName,
                    lastName:data[i].LastName,
                    titleValue:data[i].Title,
                    emailValue:data[i].Email,
                    endUserAccount:data[i].AccountId,
                    Id:data[i].Id,
                    uboID:data[i].uboID
                });
            }
            console.log('this.reviewDetail::::'+JSON.stringify(this.reviewDetail));
        } else if (error) {
            this.reviewDetail = [];
        }
    }

    //Wired method for Option Two Signers
    @wire(getContactField, {opportunityId: '$oppId', loadCount: '$contactRolesReloaded'})
    wiredGetContactOptionTwo({ error, data }){
        if (data) {
            //this.wiredRefreshList=data;
            var ownerLen=0;
            console.log(data.length);
            if(data.length < 1){
                ownerLen=1;
                this.contactDetailOptionTwo=[{
                    ownerHeading:'Signer '+ownerLen,
                    ownerNo:1,
                    firstName:'',
                    middleName:'',
                    lastName:'',
                    titleValue:'',
                    emailValue:''
                }]
            }
            console.log('data signers::'+data);
            for(var i=0;i<data.length;i++) {
                ownerLen=i+1;
                this.contactDetailOptionTwo.push({
                    ownerHeading:'Signer '+ownerLen,
                    ownerNo:ownerLen,
                    firstName:data[i].FirstName,
                    middleName:data[i].MiddleName,
                    lastName:data[i].LastName,
                    titleValue:data[i].Title,
                    emailValue:data[i].Email,
                    endUserAccount:data[i].AccountId,
                    Id:data[i].Id,
                    uboID:data[i].uboID
                });
            }
            console.log('this.contactDetailOptionTwo::::'+JSON.stringify(this.contactDetailOptionTwo));
        } else if (error) {
            this.contactDetailOptionTwo = [];
        } 
    }

    // This method is to identify the options (option 1 / Option 2)
    handleDocumentTypeChange(event){
        this.loading = true;
        this.documentTypeValue=event.detail.value;
        if(this.documentTypeValue=='option2'){
            this.docSignType=false;
        } else {
            this.docSignType=true;
        }
        saveDocusignToOpp({opportunityId : this.oppId, docusign : this.docSignType.toString()})
            .then(result => {
                this.loading = false;
            }).catch(error => {
                this.loading = false;
                console.log('error thrown');
            });
    }

    // Add Signer for Option One
    addSigner(){
        console.log('add signer');
        this.loading=true;
        var boSize=this.contactDetail.length+1;
        this.contactDetail.push({
            ownerHeading:'Signer '+boSize,
            ownerNo:boSize,
            firstName:'',
            middleName:'',
            lastName:'',
            titleValue:'',
            emailValue:''
        });
        this.loading=false;
    }

    // Add signers for Option two
    addSignerOptionTwo(){
        console.log('add signer');
       this.loading=true;
        var boSize=this.contactDetailOptionTwo.length+1;
        this.contactDetailOptionTwo.push({
            ownerHeading:'Signer '+boSize,
            ownerNo:boSize,
            firstName:'',
            middleName:'',
            lastName:'',
            titleValue:'',
            emailValue:''
        });
        this.loading=false;
    }

    // This method is to delete signers
    deleteSigner(event){
        var recordId = event.target.name;
        console.log('delete recordId::'+recordId);
        if ((typeof recordId === 'undefined') || (recordId === '')) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Record not found',
                    message: 'This record cannot be deleted since it has not been saved yet.',
                    variant: 'error'
                })
            );
        }
       deleteRecord(recordId)
        .then(() => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Record deleted',
                    variant: 'success'
                })
            );
            window.location.reload();
        }).catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                    title: 'Error deleting record',
                    message: error.body.message,
                    variant: 'error'
                })
            );
        });
        //this.loading=true;
        //refreshApex(this.wiredRefreshList);
        //this.loading=false;
    }
    
    //Handle Option one signer's first name change
    handlePersonalFirstNameChange(event){
            for(var i=0;i<this.contactDetail.length;i++) {
            if(this.contactDetail[i].ownerNo==event.target.name) {
                this.contactDetail[i].firstName=event.detail.value;
            }
            console.log('first contract name in enroll::'+this.contactDetail[i].firstName);
        }
    }

    //Handle Option one signer's Middle name change
    handleMiddleNameChange(event){
            for(var i=0;i<this.contactDetail.length;i++) {
            if(this.contactDetail[i].ownerNo==event.target.name) {
                this.contactDetail[i].middleName=event.detail.value;
            }
            console.log('middleName contract name in enroll::'+this.contactDetail[i].middleName);
        }
    }

    //Handle Option one signer's Last name change
    handleLastNameChange(event){
            for(var i=0;i<this.contactDetail.length;i++) {
            if(this.contactDetail[i].ownerNo==event.target.name) {
                this.contactDetail[i].lastName=event.detail.value;
            }
            console.log('lastName contract name in enroll::'+this.contactDetail[i].lastName);
        }
    }

    //Handle Option one signer's Title change
    handleTitlePicklistChange(event){
            for(var i=0;i<this.contactDetail.length;i++) {
            if(this.contactDetail[i].ownerNo==event.target.name) {
                this.contactDetail[i].titleValue=event.detail.value;
            }
            console.log('titleValue contract name in enroll::'+this.contactDetail[i].titleValue);
        }
    }

    //Handle Option one signer's Email change
    handleEmailChange(event){
        for(var i=0;i<this.contactDetail.length;i++) {
            if(this.contactDetail[i].ownerNo==event.target.name) {
                this.contactDetail[i].emailValue=event.detail.value;
            }
            console.log('emailValue contract name in enroll::'+this.contactDetail[i].emailValue);
        }
    }

    // *** Option Two signers on Change Method starts from here **//

    handleOptionTwoTitle(event){
        for(var i=0;i<this.contactDetailOptionTwo.length;i++) {
            if(this.contactDetailOptionTwo[i].ownerNo==event.target.name) {
                this.contactDetailOptionTwo[i].titleValue=event.detail.value;
            }
            console.log('titleValue contract name in enroll::'+this.contactDetailOptionTwo[i].titleValue);
        }
    }

    handleOptionTwoEmail(event){
        for(var i=0;i<this.contactDetailOptionTwo.length;i++) {
            if(this.contactDetailOptionTwo[i].ownerNo==event.target.name) {
                this.contactDetailOptionTwo[i].emailValue=event.detail.value;
            }
            console.log('emailValue contract name in enroll::'+this.contactDetailOptionTwo[i].emailValue);
        }
    }

    handleOptionTwoFirstName(event){
        for(var i=0;i<this.contactDetailOptionTwo.length;i++) {
            if(this.contactDetailOptionTwo[i].ownerNo==event.target.name) {
                this.contactDetailOptionTwo[i].firstName=event.detail.value;
            }
            console.log('first contract name in enroll::'+this.contactDetailOptionTwo[i].firstName);
        }
    }
    
    handleOptionTwoMidName(event){
        for(var i=0;i<this.contactDetailOptionTwo.length;i++) {
            if(this.contactDetailOptionTwo[i].ownerNo==event.target.name) {
                this.contactDetailOptionTwo[i].middleName=event.detail.value;
            }
            console.log('middleName contract name in enroll::'+this.contactDetailOptionTwo[i].middleName);
        }
    }
    handleOptionTwoLastName(event){
        for(var i=0;i<this.contactDetailOptionTwo.length;i++) {
            if(this.contactDetailOptionTwo[i].ownerNo==event.target.name) {
                this.contactDetailOptionTwo[i].lastName=event.detail.value;
            }
            console.log('lastName contract name in enroll::'+this.contactDetailOptionTwo[i].lastName);
        }
    }
    // *** Option Two signers on Change Method End here **//

    // Add Reviwers for both the options (Option1/Option2)
    addReviewer(){
        console.log('add reviewer');
        this.loading=true;
        var boSize=this.reviewDetail.length+1;
        this.reviewDetail.push({
            ownerHeading:'Reviewer '+boSize,
            ownerNo:boSize,
            firstName:'',
            middleName:'',
            lastName:'',
            titleValue:'',
            emailValue:''
        });
        this.loading=false;
    }

    // This method is to delete reviewer
    deleteReviewer(event){
        var recordId = event.target.name;
        console.log('delete recordId::'+recordId);
        if ((typeof recordId === 'undefined') || (recordId === '')) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Record not found',
                    message: 'This record cannot be deleted since it has not been saved yet.',
                    variant: 'error'
                })
            );
        }
       deleteRecord(recordId)
        .then(() => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Record deleted',
                    variant: 'success'
                })
            );
            window.location.reload();
        }).catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                    title: 'Error deleting record',
                    message: error.body.message,
                    variant: 'error'
                })
            );
        });
    }

    //Handle Option One and Two reviewer's first name change
    handleReviewerFirstNameChange(event){
        console.log('handleReviewerFirstNameChange');
        for(var i=0;i<this.reviewDetail.length;i++) {
            if(this.reviewDetail[i].ownerNo==event.target.name) {
                this.reviewDetail[i].firstName=event.detail.value;
                console.log('Reviewer firstName Change::'+this.reviewDetail[i].firstName);
            }
        }
    }

    //Handle Option One and Two reviewer's middle name change
    handleReviewerMiddleNameChange(event){
        console.log('handleReviewerMiddleNameChange');
        for(var i=0;i<this.reviewDetail.length;i++) {
            if(this.reviewDetail[i].ownerNo==event.target.name) {
                this.reviewDetail[i].middleName=event.detail.value;
                 console.log('Reviewer middleName Change::'+this.reviewDetail[i].middleName);
            }
        }
    }

    //Handle Option One and Two reviewer's last name change
    handleReviewerLastNameChange(event){
        console.log('handleReviewerLastNameChange');
        for(var i=0;i<this.reviewDetail.length;i++) {
            if(this.reviewDetail[i].ownerNo==event.target.name) {
                this.reviewDetail[i].lastName=event.detail.value;
                console.log('Reviewer lastName Change::'+this.reviewDetail[i].lastName);
            }
        }
    }

    //Handle Option One and Two reviewer's title change
    handleReviewerTitleChange(event){
        console.log('handleReviewerTitleChange');
        for(var i=0;i<this.reviewDetail.length;i++) {
            if(this.reviewDetail[i].ownerNo==event.target.name) {
                this.reviewDetail[i].titleValue=event.detail.value;
                console.log('Reviewer titleValue Change::'+this.reviewDetail[i].titleValue);
            }
        }
    }

    //Handle Option One and Two reviewer's first Email change
    handleReviewerEmailChange(event){
        console.log('handleReviewerEmailChange');
        for(var i=0;i<this.reviewDetail.length;i++) {
            if(this.reviewDetail[i].ownerNo==event.target.name) {
                this.reviewDetail[i].emailValue=event.detail.value;
                console.log('Reviewer Email Change::'+this.reviewDetail[i].emailValue);
            }
        }
    }
}