/**
 * @description       : To get account page header details
 * @author            : Kritika Sharma (Traction on Demand)
 * @group             : 
 * @last modified on  : 10-03-2022
 * @last modified by  : Kritika Sharma
**/
import { LightningElement,api, wire, track} from 'lwc';

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