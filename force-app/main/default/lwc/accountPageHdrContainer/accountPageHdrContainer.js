/**
 * @description       : To get account page header details
 * @author            : Kritika Sharma (Traction on Demand)
 * @group             : 
 * @last modified on  : 10-03-2022
 * @last modified by  : Kritika Sharma
**/
import { LightningElement,api, wire, track} from 'lwc';

import {checkPermission} from 'c/dodJSUtility';//PBI-810432 - Dibyendu

import getAccountField from '@salesforce/apex/AccountPageHeader.getAccountData';
import createNewOppForCreditCheck from '@salesforce/apex/AccountPageHeader.createNewOppForCreditCheck';
import {NavigationMixin} from 'lightning/navigation';
import { CurrentPageReference } from 'lightning/navigation';

import CREDITCHECK_ENABLED from '@salesforce/label/c.CREDITCHECK_ENABLED';

export default class AccountPageHdrContainer extends NavigationMixin(LightningElement) {

    @api recordId;
    name;
    accountNumber;
    industry;
    accountId;

    //Button/Link Permissions//PBI-810432 - Dibyendu
    CQ01 = false;

    renderCreditCheckButton = false;

    labels = [CREDITCHECK_ENABLED];

    @wire(CurrentPageReference)
    getpageRef(pageRef) {
        console.log('data => ', JSON.stringify(pageRef));
        this.recordId = pageRef.attributes.recordId;
    }

    

    @wire(getAccountField, {accountId: '$recordId'})
    wiredgetAccountRecord({ error, data }) {
        if (data) {
            console.log('Account Data::', data);
            this.name = data.Name;
            this.accountNumber = data.AccountNumber;
            this.industry = data.Industry;
            if (this.labels[0].toLowerCase() === 'true') {
                this.renderCreditCheckButton = true;
            }
        } else{
            if (typeof error === 'undefined') {
                return;
            }
            console.log('error:'+error);
            console.log(JSON.parse(JSON.stringify(error)));
        }
    }

    //method to check if the permission is true or false; this drives display of the button or link//PBI-810432 - Dibyendu
    async setPermissions() {    
         this.CQ01 = await checkPermission('CQ01'); 
         //this.CQ01 =  checkPermission('CQ01'); 
        // alert('CQ01:'+this.CQ01.value);

    }
    validateCondition() { 
        if(this.CQ01 == true && this.renderCreditCheckButton == true){
            this.renderCreditCheckButton=true;
            console.log('render Value1',this.renderCreditCheckButton);
        }
        else{
            this.renderCreditCheckButton=false;
            console.log('render Value2',this.renderCreditCheckButton);
        }
    }
    //calling connectedCallback
    connectedCallback() {

    }
    renderedCallback() {
        console.log('render Value',this.renderCreditCheckButton);
        this.setPermissions();
        setTimeout(() => {
            //this.loading = false;
            this.validateCondition();
            
        }, 2000);
    }

    navigateToCreditCheck(event) {
        createNewOppForCreditCheck({endUserId : this.recordId})
        .then(result => {
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: '/dllondemand/s/opportunity/' + result
                }
            });
        }).catch(error => {
            console.log('Error creating new opportunity for credit check.');
        });
    }
}