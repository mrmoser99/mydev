/**
 * @description       : LWC component to combine all other Entitlement (Enroll in Financing) components. 
 * @author            : Kritika Sharma : Traction on Demand
 * @group             : Kritika Sharma & Surbhi Goyal :  Traction on Demand
 * @last modified on  : 13-06-2022
 * @last modified by  : Kritika Sharma
 * @last modified by  : Geetha Bharadwaj on 6/13/2022
**/
import { LightningElement,api,wire } from 'lwc';
import getOpportunityField from '@salesforce/apex/EnrollController.getOpportunityData';
import sendDocsForFunding from '@salesforce/apex/EnrollRequestDocsIncoming.sendDocsForFunding';

import saveFundingDate from '@salesforce/apex/EnrollController.saveFundingDate';
import getPicklistOptions from '@salesforce/apex/EnrollController.picklistValues';
import updateStep from '@salesforce/apex/EnrollController.updateStep';
import updateAssetDetails from '@salesforce/apex/EnrollController.updateAssetDetails';
import { CurrentPageReference } from 'lightning/navigation'
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import sendEmailforOpportunity from '@salesforce/apex/EnrollRequestDocsIncoming.sendEmailforOpportunity';
import updateSignersDetails from '@salesforce/apex/EnrollController.updateSignersDetails';
import updateReviewersDetails from '@salesforce/apex/EnrollController.updateReviewersDetails';
import updateContactRoleData from '@salesforce/apex/EnrollController.updateContactRoleData';

// Custom Labels
import ENROLL_CUST_NAME from '@salesforce/label/c.ENROLL_CUST_NAME';
import ENROLL_APP_NUM from '@salesforce/label/c.ENROLL_APP_NUM';
import ENROLL_NICKNAME from '@salesforce/label/c.ENROLL_NICKNAME';
import ENROLL_QUOTE_NO from '@salesforce/label/c.ENROLL_QUOTE_NO';
import ENROLL_STATUS from '@salesforce/label/c.ENROLL_STATUS';
import ENROLL_ASSET_SAVED from '@salesforce/label/c.ENROLL_ASSET_SAVED';
import ENROL_PRO_BAR_ASSET_DETAIL from '@salesforce/label/c.ENROL_PRO_BAR_ASSET_DETAIL';
import ENROLL_ASSET_ERROR from '@salesforce/label/c.ENROLL_ASSET_ERROR';
import ENROLL_ASSET_ERROR_TITLE from '@salesforce/label/c.ENROLL_ASSET_ERROR_TITLE';

export default class EnrollHeader extends LightningElement {
    @api sectionTitle = "Let's Enroll in Financing";
    stepsListResult;
    label = {
        ENROLL_ASSET_ERROR,
        ENROLL_ASSET_ERROR_TITLE,
        ENROLL_STATUS,
        ENROLL_QUOTE_NO,
        ENROLL_NICKNAME,
        ENROLL_APP_NUM,
        ENROLL_CUST_NAME,
        ENROLL_ASSET_SAVED,
        ENROL_PRO_BAR_ASSET_DETAIL
    };

    // changes detail page by variable
    reviewSpecs=true;
    completeAssetDetails=false;
    reviewCustomerBilling=false;
    requestDocuments=false;
    submitDocuments=false;
    submitDocumentsConfirm=false;
    completeFunding=false;
    isReviewDoc = false;
    booked=false;
    fundingDate;

    loading = false;

    editModeVar=true;
    headerActionBtn="Edit";
    oppId = null;
    opportunityId;
    customerName;

    applicationNumber;
    nickname;
    quoteNumber;
    status;

    firstTimePage=false;

    //Model Pop-up on click of cancel button
    isModalOpen = false;

    //To check whether user edit complete asset details table or not
    isComAssetDetailsChanged = false;

    // Get record details by passing OppId in URL
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.oppId = currentPageReference.state.oppId;
        }
    }

    connectedCallback(){
        getPicklistOptions({ objectName : 'Opportunity',  fieldName : 'Enrollment_Steps__c' }).then(data =>{
            if (data) {
                this.stepsListResult=data;
                getOpportunityField({opportunityId: this.oppId}).then(data =>{
                    if (data) {
                        this.customerName=data.End_User__r.Name;
                        this.applicationNumber=data.Application_Number__c;
                        this.nickname=data.Nickname__c;
                        this.quoteNumber = data.Opportunity_Number__c;
                        this.status=data.Sub_Stage__c;
                        if (data.Sub_Stage__c == 'Booked')
                            this.booked = true;
                        else
                            this.booked = false;
                        console.log('this.status:'+this.status);
                        console.log('data.Enrollment_Steps__c::'+data.Enrollment_Steps__c);
                        var enrollStepResult=data.Enrollment_Steps__c!=null && data.Enrollment_Steps__c!=undefined && data.Enrollment_Steps__c!='' ? data.Enrollment_Steps__c : this.stepsListResult[0];
                        this.template.querySelector('c-enroll-progress-bar').selectedStep=enrollStepResult;
                        console.log('A1');
                        this.firstTimePage=true;
                        console.log('A2');
                        this.handleStepChangeValue(enrollStepResult);
                        console.log('A3');
                        const custEvent = new CustomEvent('editmode', {detail: 'true'});
                        this.dispatchEvent(custEvent);
                        console.log('A4');
                    } 
                });
            } 
        });
    }

    //Handling on click action on Edit Button.
    onActionBtnClick(){
        this.loading = true;
        if(this.headerActionBtn=='Edit') {
            this.headerActionBtn='Save';
            this.editModeVar=false;
        }
        this.loading = false;
    }

    // Handling progress bar status change on click of continue button.
    handleOnContinue(){
        this.submitDocumentsConfirm = false;
        this.loading = true;
        this.headerActionBtn='Save';
        this.editModeVar=false;
        this.handleStepChangeValue(this.template.querySelector('c-enroll-progress-bar').changeProgressBarStatus());
        //this.handleOnSave();
        this.loading = false;
    }

    closeConfirm(){
        console.log('closing confirm' + this.submitDocumentsConfirm);

        this.submitDocumentsConfirm = false;

    }
    
    handleRequestFundingShow(){

        this.submitDocumentsConfirm = true;
    }
    

     handleRequestFunding(){

        

        sendDocsForFunding({oppId: this.oppId})
         .then(result => {
                console.log('result is:' + result);
                this.fundingDate = result;
                 const evt = new ShowToastEvent({
                    title:      'Success',
                    message:    'Documents have been sent to Sales Support for theFunding Request!',
                    variant:    'success',
                    duration:   5000
                });
                this.dispatchEvent(evt);
            })
            .catch(error => {
                const evt = new ShowToastEvent({
                    title:      'Error',
                    message:    'An error occurred',
                    variant:    'error',
                    duration:   20000
            });
            this.dispatchEvent(evt);
                        
        });
        
       
        
        saveFundingDate({opportunityId: this.oppId})
            .then(result => {
                console.log('result is:' + result);
                this.fundingDate = result;
                const evt = new ShowToastEvent({
                    title: 'Success',
                    message: 'Application has been submitted for Funding!',
                    variant: 'success',
                    duration: 3000
                });
                this.dispatchEvent(evt);
                this.handleOnContinue();
                         
            })
            .catch(error => {
                const evt = new ShowToastEvent({
                    title:      'Error',
                    message:    'An error occurred',
                    variant:    'error',
                    duration:   20000
            });
            this.dispatchEvent(evt);
                        
        });
        
         
        

         
    }

    //Handle Send email button
     // Handling progress bar status change on click of continue button.
     /*handleOnSendEmail(){                                     
        this.loading = true;
        console.log('continue :::');
        this.headerActionBtn='Save';
        this.editModeVar=false;
        this.handleStepChangeValue(this.template.querySelector('c-enroll-progress-bar').changeProgressBarStatus());
        this.loading = false;

        //calling method
        sendEmailforOpportunity({oppId:this.oppId}).then(data =>{});

        const evt = new ShowToastEvent({
                    title:      'Request Documents',
                    message:    'Request for documents has been submitted to DLL on Demand support!',
                    variant:    'success',
                    duration:   5000
                });
                this.dispatchEvent(evt);
            
    }*/


    // Handling progress bar status change on click of Back button.
    handleOnBack(){
        this.loading = true;
        console.log('Back :::');
        this.headerActionBtn='Save';
        this.editModeVar=false;
        this.handleStepChangeValue(this.template.querySelector('c-enroll-progress-bar').getBackToPReviousState());
        //window.location.reload();
        this.loading = false;
    }

    // Handling progress bar status change values.
    handleStepChangeValue(selectedStep){
        console.log('selectedStep:::'+selectedStep);
        console.log('this.stepsListResult:::'+this.stepsListResult);
        if(selectedStep==this.stepsListResult[0]){
            console.log('this.stepsListResult[0]:::'+this.stepsListResult[0]);
            this.editModeVar=true;
            this.reviewSpecs=true;
            this.completeAssetDetails=false;
            this.reviewCustomerBilling=false;
            this.requestDocuments=false;
            this.submitDocuments=false;
            this.completeFunding=false;
            this.isReviewDoc = false;
        } else if(selectedStep==this.stepsListResult[1]){
            console.log('this.stepsListResult[1]:::'+this.stepsListResult[1]);
            this.editModeVar=false;
            this.reviewSpecs=false;
            this.completeAssetDetails=true;
            this.reviewCustomerBilling=false;
            this.requestDocuments=false;
            this.submitDocuments=false;
            this.completeFunding=false;
            this.isReviewDoc = false;
        } else if(selectedStep==this.stepsListResult[2]){
            console.log('this.stepsListResult[2]:::'+this.stepsListResult[2]);
            this.editModeVar=false;
            this.reviewSpecs=false;;
            this.completeAssetDetails=false;
            this.reviewCustomerBilling=true;
            this.requestDocuments=false;
            this.submitDocuments=false;
            this.completeFunding=false;
            this.isReviewDoc = false;
        } else if(selectedStep==this.stepsListResult[3]){
            console.log('this.stepsListResult[3]:::'+this.stepsListResult[3]);
            this.editModeVar=false;
            this.reviewSpecs=false;;
            this.completeAssetDetails=false;
            this.reviewCustomerBilling=false;
            this.requestDocuments=true;
            this.submitDocuments=false;
            this.completeFunding=false;
            this.isReviewDoc = true; //Geetha for Request Documents button (Outbound Email)
        } else if(selectedStep==this.stepsListResult[4]){
            console.log('this.stepsListResult[4]:::'+this.stepsListResult[4]);
            this.editModeVar=false;
            this.reviewSpecs=false;;
            this.isReviewDoc = false;
            this.completeAssetDetails=false;
            this.reviewCustomerBilling=false;
            this.requestDocuments=false;
            this.submitDocuments=true;
            this.completeFunding=false;
        } else if(selectedStep==this.stepsListResult[5]){
            console.log('this.stepsListResult[5]:::'+this.stepsListResult[5]);
            this.editModeVar=false;
            this.reviewSpecs=false;;
            this.isReviewDoc = false;
            this.completeAssetDetails=false;
            this.reviewCustomerBilling=false;
            this.requestDocuments=false;
            this.submitDocuments=false;
            this.completeFunding=true;
            
        }
        console.log('this.updateEnrollStepValue::'+this.updateEnrollStepValue);
        if(this.firstTimePage==false){
            this.updateEnrollStepValue(selectedStep);
        } else {
            this.firstTimePage=false;
        }
        
    }

    // Updating Enrolment status values.
    updateEnrollStepValue(selectedStep){
        console.log('selectedStep test::'+selectedStep);
        console.log('this.oppId test::'+this.oppId);
        updateStep({enrollStep:selectedStep , oppId:this.oppId})
        .then(result => {
            console.log('result:::'+JSON.stringify(result));
            //window.location.reload();
        })
        .catch(error => {
            console.log('error::'+JSON.stringify(error));
        }) 
    }

    validateSignersData(objArr) {
        for (let i = 0; i < objArr.length; i++) {
            if ((objArr[i].firstName !== '') || (objArr[i].lastName !== '') || (objArr[i].titleValue !== '') || (objArr[i].emailValue !== '')) {
                if ((objArr[i].firstName === '') || (objArr[i].lastName === '') || (objArr[i].titleValue === '') || (objArr[i].emailValue === '')) {
                    return false;
                }
            }
        }
        return true;
    }

    validateReviewersData(objArr) {
        for (let i = 0; i < objArr.length; i++) {
            if ((objArr[i].firstName !== '') || (objArr[i].lastName !== '') || (objArr[i].emailValue !== '')) {
                if ((objArr[i].firstName === '') || (objArr[i].lastName === '') || (objArr[i].emailValue === '')) {
                    return false;
                }
            }
        }
        return true;
    }

    validateEmail(objArr) {
        for (let i = 0; i < objArr.length; i++) {
            if (objArr[i].emailValue.split('@').length !== 2) {
                return false;
            }
            if (objArr[i].emailValue.split('@')[1].split('.').length === 1) {
                return false;
            }
            let dotsInDomainName = objArr[i].emailValue.split('@')[1].split('.');
            for (let i = 0; i < dotsInDomainName.length; i++) {
                if (dotsInDomainName[i].length === 0) {
                    return false;
                }
                for (let j = 0; j < dotsInDomainName[i].length; j++) {
                    let charAt = dotsInDomainName[i][j];
                    if ((charAt !== '-') && ((charAt > '9') || (charAt < '0')) && ((charAt > 'z') || (charAt < 'a')) && ((charAt > 'Z') || (charAt < 'A'))) {
                        return false;
                    }
                }
            }
        }

        return true;
    }

    filterOutBlankSignersAndReviewers(objArr) {
        let result = [];
        for (let i = 0; i < objArr.length; i++) {
            if ((objArr[i].firstName !== '') || (objArr[i].lastName !== '') || (objArr[i].titleValue !== '') || (objArr[i].emailValue !== '')) {
                result.push(objArr[i]);
            }
        }
        return result;
    }

    isUSPhone(input) {
        if ((input.length !== 10) && (input.length !== 12)) {
            return false;
        }

        for (let i = 0; i < input.length; i++) { 
            if (((i === 3) || (i === 7)) && (input[i] !== '-') && (input.length === 12)) {
                return false;
            }
            if ( ((input[i] >= '0') && (input[i] <= '9')) || (((i === 3) || (i === 7)) && (input[i] === '-') && (input.length === 12)) ) {
                continue;
            }
            return false;
        }

        return true;
    }

    handleOnSave(){
        this.isComAssetDetailsChanged = true;
        var errorOccur = false;
        //Complete assets details
        if(this.completeAssetDetails==true){

            // Validate the asset list
            var assetsValid = true;
            for(var i=0; i<this.template.querySelector('c-enroll-assets').assetsList.length; i++){
                var asset = this.template.querySelector('c-enroll-assets').assetsList[i];
                if(asset.serviceFee != null){
                    var decimals = asset.serviceFee.toString().split('.');
                    if(decimals.length > 1) {

                        // Only allow up to two decimal points.
                        if(decimals[1].length >= 3){
                            assetsValid = false;
                            break;
                        }
                    }
                }
            }

            // Stop the saving process.
            if(assetsValid == false){
                // Immediate feedback
                const evt = new ShowToastEvent({
                    title:      ENROLL_ASSET_ERROR_TITLE,
                    message:    ENROLL_ASSET_ERROR,
                    variant:    'error',
                    duration:   10000
                });
                this.dispatchEvent(evt);
                this.loading = false;

                return;
            }

            this.loading = true;
            console.log('assetsList', this.template.querySelector('c-enroll-assets').assetsList);
            updateAssetDetails({assetRecords: this.template.querySelector('c-enroll-assets').assetsList}).then(result => {
                const evt = new ShowToastEvent({
                    title: ENROL_PRO_BAR_ASSET_DETAIL,
                    message: ENROLL_ASSET_SAVED,
                    variant: 'success',
                    duration: 10000,
                });
                this.dispatchEvent(evt);
                this.loading = false;
                window.location.reload();
            })
            .catch(error => {
                console.log('error::'+JSON.stringify(error));
            }) 
        }
        //Review Customer Billing info
        if(this.reviewCustomerBilling==true){
            this.loading = true;
            console.log('customer billing info::'+this.reviewCustomerBilling);
            const customerBillingContact = this.template.querySelector('c-enroll-customer-billing').contactData;
            const customerBillingConfirmedAddress = this.template.querySelector('c-enroll-customer-billing').addressConfirmed;
            if (!customerBillingConfirmedAddress) {
                const evt = new ShowToastEvent({
                    title:      'Customer Billing Information',
                    message:    'You must confirm that the billing address displayed is correct (checkbox at bottom)',
                    variant:    'error',
                    duration:   20000
                });
                this.dispatchEvent(evt);
                this.loading = false;
                return;
            }
            console.log(JSON.parse(JSON.stringify(customerBillingContact)));
            if (customerBillingContact) {
                if ((typeof customerBillingContact.firstName === 'undefined') ||
                (typeof customerBillingContact.lastName === 'undefined') ||
                (typeof customerBillingContact.phone === 'undefined') || 
                (typeof customerBillingContact.email === 'undefined') || 
                (customerBillingContact.firstName === '') || 
                (customerBillingContact.lastName === '') || 
                (customerBillingContact.phone === '') || 
                (customerBillingContact.email === '')) {
                    const evt = new ShowToastEvent({
                        title:      'Customer Billing Information',
                        message:    'There is a missing field in the billing contact',
                        variant:    'error',
                        duration:   20000
                    });
                    this.dispatchEvent(evt);
                    this.loading = false;
                    return;
                }
                if (!this.isUSPhone(customerBillingContact.phone)) {
                    const evt = new ShowToastEvent({
                        title:      'Customer Billing Information',
                        message:    'The phone number entered on the billing contact is incorrect',
                        variant:    'error',
                        duration:   20000
                    });
                    this.dispatchEvent(evt);
                    this.loading = false;
                    return;
                }
                let inputValue = [];
                let inputDataValue = {
                    firstName : customerBillingContact.firstName,
                    lastName : customerBillingContact.lastName,
                    phoneNumber : customerBillingContact.phone,
                    email : customerBillingContact.email
                };
                if (customerBillingContact.uboID) {
                    inputDataValue.uboID = customerBillingContact.uboID;
                    inputDataValue.Id = customerBillingContact.Id;
                }
                inputValue.push(inputDataValue);
                console.log(JSON.parse(JSON.stringify(inputValue)));
                //return;
                updateContactRoleData({contactRecord : inputValue, opportunityId : this.oppId})
                    .then(result => {
                        const evt = new ShowToastEvent({
                            title: 'Enroll Document Billing Contact',
                            message: 'Enroll Document Billing Contact saved',
                            variant: 'success',
                            duration: 10000,
                        });
                        this.dispatchEvent(evt);
                        window.location.reload();
                    })
                    .catch(error => {
                        const evt = new ShowToastEvent({
                            title:      'Customer Billing Information',
                            message:    'An error occured saving the billing contact',
                            variant:    'error',
                            duration:   20000
                        });
                        this.dispatchEvent(evt);
                        console.log('Error saving billing contact');
                        this.loading = false;
                    });
            }
        }
        //Request Document
        if(this.requestDocuments==true){
            this.loading = true;
            let apexCallsToWaitFor = 0;
            console.log('test request Documents');
            console.log('test121'+JSON.stringify(this.template.querySelector('c-enroll-request-doc').contactDetail));
            console.log('test122321'+JSON.stringify(this.template.querySelector('c-enroll-request-doc').reviewDetail));
            console.log('test option 2 signer'+JSON.stringify(this.template.querySelector('c-enroll-request-doc').contactDetailOptionTwo));
            const contactDetailList = this.filterOutBlankSignersAndReviewers(this.template.querySelector('c-enroll-request-doc').contactDetail);
            const reviewDetail = this.filterOutBlankSignersAndReviewers(this.template.querySelector('c-enroll-request-doc').reviewDetail);
            const contactDetailOptionTwo = this.filterOutBlankSignersAndReviewers(this.template.querySelector('c-enroll-request-doc').contactDetailOptionTwo);
            const docusignType = this.template.querySelector('c-enroll-request-doc').docusignType;
            console.log('docusignType::' + docusignType);
            if ((contactDetailList.length === 0) && (reviewDetail.length === 0) && (contactDetailOptionTwo.length === 0)) {
                const evt = new ShowToastEvent({
                    title:      'Request Financing Documents',
                    message:    'There is no data entered for signers or reviewers',
                    variant:    'error',
                    duration:   20000
                });
                this.dispatchEvent(evt);
                this.loading = false;
                return;
            }
            if((contactDetailList.length !== 0) && docusignType) {
                apexCallsToWaitFor++;
                if(!this.validateSignersData(contactDetailList)) {
                    const evt = new ShowToastEvent({
                        title:      'Request Financing Documents',
                        message:    'There is a missing field in one of the signers',
                        variant:    'error',
                        duration:   20000
                    });
                    this.dispatchEvent(evt);
                    this.loading = false;
                    return;
                }
                if(!this.validateEmail(contactDetailList)) {
                    const evt = new ShowToastEvent({
                        title:      'Request Financing Documents',
                        message:    'There is an invalid email in one of the signers',
                        variant:    'error',
                        duration:   20000
                    });
                    this.dispatchEvent(evt);
                    this.loading = false;
                    return;
                }
            }
            if(reviewDetail.length !== 0) {
                apexCallsToWaitFor++;
                if(!this.validateReviewersData(reviewDetail)) {
                    const evt = new ShowToastEvent({
                        title:      'Request Financing Documents',
                        message:    'There is a missing field in one of the reviewers',
                        variant:    'error',
                        duration:   20000
                    });
                    this.dispatchEvent(evt);
                    this.loading = false;
                    return;
                }
                if(!this.validateEmail(reviewDetail)) {
                    const evt = new ShowToastEvent({
                        title:      'Request Financing Documents',
                        message:    'There is an invalid email in one of the reviewers',
                        variant:    'error',
                        duration:   20000
                    });
                    this.dispatchEvent(evt);
                    this.loading = false;
                    return;
                }
            }
            if((contactDetailOptionTwo.length !== 0) && !docusignType) {
                apexCallsToWaitFor++;
                if(!this.validateSignersData(contactDetailOptionTwo)) {
                    const evt = new ShowToastEvent({
                        title:      'Request Financing Documents',
                        message:    'There is a missing field in one of the signers',
                        variant:    'error',
                        duration:   20000
                    });
                    this.dispatchEvent(evt);
                    this.loading = false;
                    return;
                }
                if(!this.validateEmail(contactDetailOptionTwo)) {
                    const evt = new ShowToastEvent({
                        title:      'Request Financing Documents',
                        message:    'There is an invalid email in one of the signers',
                        variant:    'error',
                        duration:   20000
                    });
                    this.dispatchEvent(evt);
                    this.loading = false;
                    return;
                }
            }
            if((contactDetailList.length !== 0) && docusignType){
                updateSignersDetails({signersRecords:contactDetailList,opportunityId: this.oppId}).then(result => {
                    console.log('signers result'+result);
                    const evt = new ShowToastEvent({
                    title: 'Enroll Document Request signer',
                    message: 'Enroll Document Request signer saved',
                    variant: 'success',
                    duration: 10000,
                });
                this.dispatchEvent(evt);
                //console.log('Contacts First Edited...');
                //console.log(result);
                //return;
                apexCallsToWaitFor--;
                if(apexCallsToWaitFor === 0) {
                    this.loading = false;
                    window.location.reload();
                }
                    
            })
            .catch(error => {
                console.log('error::'+JSON.stringify(error));
                return;
                apexCallsToWaitFor--;
                if(apexCallsToWaitFor === 0) {
                    this.loading = false;
                    window.location.reload();
                }
            }) 
            } else if ((contactDetailList.length === 0) && docusignType) {
                // Immediate feedback
                const evt = new ShowToastEvent({
                    title:      'Request Financing Documents',
                    message:    'Please add at least one Signer record',
                    variant:    'error',
                    duration:   20000
                });
                this.dispatchEvent(evt);
                this.loading = false;
                return;
            }
            //Review's section
            if(reviewDetail.length !== 0){
                updateReviewersDetails({reviewersRecords:reviewDetail,opportunityId: this.oppId}).then(result => {
                const evt = new ShowToastEvent({
                    title: 'Enroll Document Request Reviewers',
                    message: 'Enroll Document Request Reviewer saved',
                    variant: 'success',
                    duration: 10000,
                });
                this.dispatchEvent(evt);
                apexCallsToWaitFor--;
                if(apexCallsToWaitFor === 0) {
                    this.loading = false;
                    window.location.reload();
                }
                //window.location.reload();
            }).catch(error => {
                    apexCallsToWaitFor--;
                    if(apexCallsToWaitFor === 0) {
                        this.loading = false;
                        window.location.reload();
                    }
                    console.log('error::'+JSON.stringify(error));
                }) 
            }
            //Signer's section for Option 2
            if((contactDetailOptionTwo.length !== 0) && !docusignType){
                updateSignersDetails({signersRecords:contactDetailOptionTwo,opportunityId: this.oppId}).then(result => {
                const evt = new ShowToastEvent({
                    title: 'Enroll Document Request signer',
                    message: 'Enroll Document Request signer saved',
                    variant: 'success',
                    duration: 10000,
                });
                this.dispatchEvent(evt);
                //console.log('Contacts Edited...');
                //console.log(result);
                //return;
                apexCallsToWaitFor--;
                if(apexCallsToWaitFor === 0) {
                    this.loading = false;
                    window.location.reload();
                }
                //window.location.reload();
            }).catch(error => {
                console.log('error::'+JSON.stringify(error));
                return;
                    apexCallsToWaitFor--;
                    if(apexCallsToWaitFor === 0) {
                        this.loading = false;
                        window.location.reload();
                    }
                }); 
            }
            //window.location.reload();
        }
        
    }
    //Open model pop-up to Notify user for save/cancel the changes you made on click of continue button
    openModal() {
        this.isModalOpen = true;
    }
     //Close model pop-up to Notify user for save/cancel the changes you made on click of continue button
    closeModal() {
        this.isModalOpen = false;
    }

    submitDetails() {
        //calling method if user edit complete asset details.
        this.isModalOpen = false;
        this.handleOnSave();
    }

    handleOnSendEmail(){
        this.loading = true;
        console.log('continue :::');
        this.headerActionBtn='Save';
        this.editModeVar=false;
        this.handleStepChangeValue(this.template.querySelector('c-enroll-progress-bar').changeProgressBarStatus());
        this.loading = false;

        //calling method

        sendEmailforOpportunity({oppId:this.oppId}).then(data =>{});

        const evt = new ShowToastEvent({
            title:      'Request Documents',
            message:    'Request for documents has been submitted to DLL on Demand support!',
            variant:    'success',
            duration:   5000
        });

        this.dispatchEvent(evt);
    }
}