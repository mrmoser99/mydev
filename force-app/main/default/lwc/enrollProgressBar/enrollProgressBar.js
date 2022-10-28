/**
 * @description       : LWC component for Enroll Progress Bar. 
 * @author            : Kritika Sharma : Traction on Demand
 * @group             : Kritika Sharma & Surbhi Goyal :  Traction on Demand
 * @last modified on  : 10-05-2022
 * @last modified by  : Kritika Sharma
**/
import { LightningElement,api,wire } from 'lwc';
import getPicklistOptions from '@salesforce/apex/EnrollController.picklistValues';

// Custom Labels
import ENROL_PRO_BAR_REVIEW_SPEC from '@salesforce/label/c.ENROL_PRO_BAR_REVIEW_SPEC';
import ENROL_PRO_BAR_ASSET_DETAIL from '@salesforce/label/c.ENROL_PRO_BAR_ASSET_DETAIL';
import ENROL_PRO_BAR_CUST_BILLING from '@salesforce/label/c.ENROL_PRO_BAR_CUST_BILLING';
import ENROL_PRO_BAR_REQ_DOC from '@salesforce/label/c.ENROL_PRO_BAR_REQ_DOC';
import ENROL_PRO_BAR_SUBMIT_DOC from '@salesforce/label/c.ENROL_PRO_BAR_SUBMIT_DOC';
import ENROL_PRO_BAR_COMPLETE_FUNDING from '@salesforce/label/c.ENROL_PRO_BAR_COMPLETE_FUNDING';

export default class EnrollProgressBar extends LightningElement {

    label = {
        ENROL_PRO_BAR_REVIEW_SPEC,
        ENROL_PRO_BAR_ASSET_DETAIL,
        ENROL_PRO_BAR_CUST_BILLING,
        ENROL_PRO_BAR_REQ_DOC,
        ENROL_PRO_BAR_SUBMIT_DOC,
        ENROL_PRO_BAR_COMPLETE_FUNDING
    };

    stepsList;//=['Review Specs','Complete Asset Details','Review Customer Billing','Request Documents','Submit Documents','Complete Funding'];
    @api selectedStep = 'Review Specs';
 
    @wire(getPicklistOptions,{ objectName : 'Opportunity',  fieldName : 'Enrollment_Steps__c' })
    wiredGetPicklistOptions({error, data}) {
        if (data) {
            console.log('data::'+JSON.stringify(data));
            this.stepsList=data;
            console.log('this.stepsList ::'+this.stepsList);
            //this.selectedStep = this.stepsList[0];
        } else if (error) {
            console.log('Error ::'+error);
        }
    }

    handleNext() {
        var getselectedStep = this.selectedStep;
        if(getselectedStep == this.stepsList[0]){
            this.selectedStep = this.stepsList[1];
        }
        else if(getselectedStep == this.stepsList[1]){
            this.selectedStep = this.stepsList[2];
        }
        else if(getselectedStep == this.stepsList[2]){
            this.selectedStep = this.stepsList[3];
        } 
        else if(getselectedStep == this.stepsList[3]){
            this.selectedStep = this.stepsList[4];
        } 
        else if(getselectedStep == this.stepsList[4]){
            this.selectedStep = this.stepsList[5];
        }
    }
 
    handlePrev() {
        var getselectedStep = this.selectedStep;
        if(getselectedStep === this.stepsList[1]){
            this.selectedStep = this.stepsList[0];
        }
        else if(getselectedStep === this.stepsList[2]){
            this.selectedStep = this.stepsList[1];
        }
        else if(getselectedStep === this.stepsList[3]){
            this.selectedStep = this.stepsList[2];
        }
        else if(getselectedStep === this.stepsList[4]){
            this.selectedStep = this.stepsList[3];
        }
        else if(getselectedStep === this.stepsList[5]){
            this.selectedStep = this.stepsList[4];
        }
    }
      
    handleFinish() {
        alert('Finished...');
        this.selectedStep = this.stepsList[0];
    }
      
    selectStep1() {
        this.selectedStep = this.stepsList[0];
    }
 
    selectStep2() {
        this.selectedStep = this.stepsList[1];
    }
 
    selectStep3() {
        this.selectedStep = this.stepsList[2];
    }
 
    selectStep4() {
        this.selectedStep = this.stepsList[3];
    }
 
    selectStep5(){
        this.selectedStep = this.stepsList[4];
    }

    selectStep6(){
        this.selectedStep = this.stepsList[5];
    }
    
    get isSelectStep6() {
        return this.selectedStep === this.stepsList[5];
    }

    @api changeProgressBarStatus(){
        this.handleNext();
        console.log('selectedStep::: '+this.selectedStep);
        return this.selectedStep;
    }
    @api getBackToPReviousState(){
        this.handlePrev();
        console.log('selectedStep::: '+this.selectedStep);
        return this.selectedStep;
    }
}