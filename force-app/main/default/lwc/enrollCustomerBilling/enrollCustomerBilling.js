/**
 * @description       : LWC component to display customer billing screen. 
 * @author            : Surbhi Goyal : Traction on Demand
 * @group             : Kritika Sharma & Surbhi Goyal :  Traction on Demand
 * @last modified on  : 09-06-2022
 * @last modified by  : Kritika Sharma
**/
import { LightningElement,api,wire,track } from 'lwc';

import getCustomerId from "@salesforce/apex/EnrollController.getCustomerId";
import getOpportunityData from "@salesforce/apex/EnrollController.getOpportunityData";
import getBillingContactData from "@salesforce/apex/EnrollController.getBillingContactData";
import saveNewBillingAddress from "@salesforce/apex/EnrollControllerWithoutSharing.saveNewBillingAddress";
import saveBillingPreference from "@salesforce/apex/EnrollController.saveBillingPreference"; 
import getBillingPreference from "@salesforce/apex/EnrollController.getBillingPreference"; 
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// Custom Labels
import ENROLL_CUST_BILNG_DETAILS from '@salesforce/label/c.ENROLL_CUST_BILNG_DETAILS';
import ENROLL_CUST_BILNG_CONTENT from '@salesforce/label/c.ENROLL_CUST_BILNG_CONTENT';
import ENROL_REVIEW_REQUIRED from '@salesforce/label/c.ENROL_REVIEW_REQUIRED';
import ENROLL_CUST_BILNG_INFO from '@salesforce/label/c.ENROLL_CUST_BILNG_INFO';
import ENROLL_CUST_BILNG_CONTENT1 from '@salesforce/label/c.ENROLL_CUST_BILNG_CONTENT1';
import ENROLL_CUST_BILNG_CUST_NAME from '@salesforce/label/c.ENROLL_CUST_BILNG_CUST_NAME';
import ENROLL_CUST_BILNG_PRIMARY_CONTACT from '@salesforce/label/c.ENROLL_CUST_BILNG_PRIMARY_CONTACT';

import ENROLL_CUST_BILNG_PHONE from '@salesforce/label/c.ENROLL_CUST_BILNG_PHONE';
import ENROLL_CUST_BILNG_CUST_ADDRS from '@salesforce/label/c.ENROLL_CUST_BILNG_CUST_ADDRS';
import ENROLL_CUST_BILNG_EMAIL from '@salesforce/label/c.ENROLL_CUST_BILNG_EMAIL';
import ENROLL_CUST_BILNG_TAX_NO from '@salesforce/label/c.ENROLL_CUST_BILNG_TAX_NO';
import ENROLL_CUST_BILNG_CONFIRM_CHECK from '@salesforce/label/c.ENROLL_CUST_BILNG_CONFIRM_CHECK';
import ENROLL_CUST_BILNGENTER_CUST_INFO from '@salesforce/label/c.ENROLL_CUST_BILNGENTER_CUST_INFO';
import ENROLL_CUST_BILNG_CONTEN2 from '@salesforce/label/c.ENROLL_CUST_BILNG_CONTEN2';

import ENROLL_CUST_BILNG_PHONE_NO from '@salesforce/label/c.ENROLL_CUST_BILNG_PHONE_NO';
import ENROLL_CUST_BILNG_EMAIL1 from '@salesforce/label/c.ENROLL_CUST_BILNG_EMAIL1';
import ENROLL_CUST_BILNG_ADDRS_LINE1 from '@salesforce/label/c.ENROLL_CUST_BILNG_ADDRS_LINE1';
import ENROLL_CUST_BILNG_ADDRS_LINE2 from '@salesforce/label/c.ENROLL_CUST_BILNG_ADDRS_LINE2';
import ENROLL_CUST_BILNG_CITY from '@salesforce/label/c.ENROLL_CUST_BILNG_CITY';

import ENROLL_CUST_BILNG_STATE from '@salesforce/label/c.ENROLL_CUST_BILNG_STATE';
import ENROLL_CUST_BILNG_COUNTRY from '@salesforce/label/c.ENROLL_CUST_BILNG_COUNTRY';
import ENROLL_CUST_BILNG_ZIP_CODE from '@salesforce/label/c.ENROLL_CUST_BILNG_ZIP_CODE';
import ENROLL_CUST_BILNG_SAVE_ADDRS from '@salesforce/label/c.ENROLL_CUST_BILNG_SAVE_ADDRS';
import ENROLL_CUST_DEFAULT_ADDRS from '@salesforce/label/c.ENROLL_CUST_DEFAULT_ADDRS';
import ENROLL_CUST_BILING_DIFF_FROM_DEFAULT from '@salesforce/label/c.ENROLL_CUST_BILING_DIFF_FROM_DEFAULT';

export default class EnrollCustomerBilling extends LightningElement {
    label = {
        ENROLL_CUST_BILNG_DETAILS,
        ENROLL_CUST_BILNG_CONTENT,
        ENROL_REVIEW_REQUIRED,
        ENROLL_CUST_BILNG_INFO,
        ENROLL_CUST_BILNG_CONTENT1,
        ENROLL_CUST_BILNG_CUST_NAME,
        ENROLL_CUST_BILNG_PRIMARY_CONTACT,
        ENROLL_CUST_BILNG_PHONE,
        ENROLL_CUST_BILNG_CUST_ADDRS,
        ENROLL_CUST_BILNG_EMAIL,
        ENROLL_CUST_BILNG_TAX_NO,
        ENROLL_CUST_BILNG_CONFIRM_CHECK,
        ENROLL_CUST_BILNGENTER_CUST_INFO,
        ENROLL_CUST_BILNG_CONTEN2,
        ENROLL_CUST_BILNG_PHONE_NO,
        ENROLL_CUST_BILNG_EMAIL1,
        ENROLL_CUST_BILNG_ADDRS_LINE1,
        ENROLL_CUST_BILNG_ADDRS_LINE2,
        ENROLL_CUST_BILNG_CITY,
        ENROLL_CUST_BILNG_STATE,
        ENROLL_CUST_BILNG_COUNTRY,
        ENROLL_CUST_BILNG_ZIP_CODE,
        ENROLL_CUST_BILNG_SAVE_ADDRS,
        ENROLL_CUST_DEFAULT_ADDRS,
        ENROLL_CUST_BILING_DIFF_FROM_DEFAULT
    }

    statelist = [
        {value: '', label: ''},
        {value: 'AL', label: 'AL'},
        {value: 'AK', label: 'AK'},
        {value: 'AZ', label: 'AZ'},
        {value: 'AR', label: 'AR'},
        {value: 'CA', label: 'CA'},
        {value: 'CO', label: 'CO'},
        {value: 'CT', label: 'CT'},
        {value: 'DE', label: 'DE'},
        {value: 'DC', label: 'DC'},
        {value: 'FL', label: 'FL'},
        {value: 'GA', label: 'GA'},
        {value: 'HI', label: 'HI'},
        {value: 'ID', label: 'ID'},
        {value: 'IL', label: 'IL'},
        {value: 'IN', label: 'IN'},
        {value: 'IA', label: 'IA'},
        {value: 'KS', label: 'KS'},
        {value: 'KY', label: 'KY'},
        {value: 'LA', label: 'LA'},
        {value: 'ME', label: 'ME'},
        {value: 'MD', label: 'MD'},
        {value: 'MA', label: 'MA'},
        {value: 'MI', label: 'MI'},
        {value: 'MN', label: 'MN'},
        {value: 'MS', label: 'MS'},
        {value: 'MO', label: 'MO'},
        {value: 'MT', label: 'MT'},
        {value: 'NE', label: 'NE'},
        {value: 'NV', label: 'NV'},
        {value: 'NH', label: 'NH'},
        {value: 'NJ', label: 'NJ'},
        {value: 'NM', label: 'NM'},
        {value: 'NY', label: 'NY'},
        {value: 'NC', label: 'NC'},
        {value: 'ND', label: 'ND'},
        {value: 'OH', label: 'OH'},
        {value: 'OK', label: 'OK'},
        {value: 'OR', label: 'OR'},
        {value: 'PA', label: 'PA'},
        {value: 'PR', label: 'PR'},
        {value: 'RI', label: 'RI'},
        {value: 'SC', label: 'SC'},
        {value: 'SD', label: 'SD'},
        {value: 'TN', label: 'TN'},
        {value: 'TX', label: 'TX'},
        {value: 'UT', label: 'UT'},
        {value: 'VT', label: 'VT'},
        {value: 'VA', label: 'VA'},
        {value: 'WA', label: 'WA'},
        {value: 'WV', label: 'WV'},
        {value: 'WI', label: 'WI'},
        {value: 'WY', label: 'WY'}
    ];

    @api oppId;
    @api editMode;
    editModeConverted;

    @track
    addressConfirmed = false;

    @api get addressConfirmed() {
        return this.addressConfirmed;
    }

    connectedCallback() {
        console.log('editMode: ');
        console.log(this.editMode);
        if ((this.editMode === 'false') || (this.editMode === false)) {
            this.editModeConverted = '';
        } else {
            this.editModeConverted = true;
        }
        if (this.oppId) {
            getBillingContactData({opportunityId : this.oppId})
            .then(result => {
                if (result.Id === 'no contact found') {
                    return;
                }
                this.contactData.firstName = result.FirstName;
                this.contactData.lastName = result.LastName;
                this.contactData.phone = result.Phone;
                this.contactData.email = result.Email;
                this.contactData.uboID = result.uboID;
                this.contactData.Id = result.Id;
            }).catch(error => {
                console.log('Error retrieving billing contact data');
            });
            getBillingPreference({opportunityId : this.oppId})
            .then(result => {
                if (result == 'Use existing billing address') {
                    this.customerBillingInfoValue = 'defaultAddress';
                    this.billingAddress=true;
                } else if (result == 'Enter new billing address') {
                    this.customerBillingInfoValue = 'provideNewAddress';
                    this.billingAddress=false;
                }
                console.log('Billing preference set');
            }).catch(error => {
                console.log(JSON.parse(JSON.stringify(error)));
            });
        }
    }

    //custome info variables
    objectName='Account';
    customerId;
    refreshExecute=true;
    BillingContactName;

    //customer billing info section
    customerBillingInfoOptions=[
        { label: ENROLL_CUST_DEFAULT_ADDRS, value: 'defaultAddress' },
        { label: ENROLL_CUST_BILING_DIFF_FROM_DEFAULT, value: 'provideNewAddress' },
    ];
    customerBillingInfoValue='defaultAddress';

    // boolean variable for address data visible
    billingAddress=true;

    toggleAddressConfirmed(event) {
        this.addressConfirmed = event.target.checked;
    }

    @track
    contactData = {
        firstName : '',
        lastName : '',
        phone : '',
        email : '',
        customerAccountName : ''
    };

    @api get contactData() {
        return this.contactData;
    }

    handleOnChangeContactData(event) {
        this.contactData[event.target.name] = event.target.value;
    }

    accountData = {
        addressLineOne : 'testHook',
        addressLineTwo : 'testHook',
        city : 'testHook',
        state : 'testHook',
        country : 'testHook',
        ZIPCode : 'testHook'
    };

    handleOnChangeAccountData(event) {
        this.accountData[event.target.name] = event.target.value;
    }

    newAccountData = {
        addressLineOne : 'testHook',
        addressLineTwo : 'testHook',
        city : 'testHook',
        state : 'testHook',
        country : 'testHook',
        ZIPCode : 'testHook'
    };

    handleOnChangeNewAccountData(event) {
        this.newAccountData[event.target.name] = event.target.value;
    }

    handleStateChange(event){
        this.newAccountData.state = event.detail.value;
    }

    verifyNewAccountData(obj) {
        return ((typeof obj.addressLineOne !== 'undefined') && (typeof obj.city !== 'undefined') && (obj.state !== 'undefined') && (obj.country !== 'undefined') && (typeof obj.ZIPCode !== 'undefined') && 
        (obj.addressLineOne !== '') && (obj.city !== '') && (obj.state !== '') && (obj.country !== '') && (obj.ZIPCode !== ''));
    }

    verifyZipCode(str) {
        if (str.length !== 5) {
            return false;
        }

        for (let i = 0; i < str.length; i++) {
            if ((str[i] < '0') || (str[i] > '9')) {
                return false;
            }
        }

        return true;
    }

    handleSaveAddress(event) {
        console.log(JSON.parse(JSON.stringify(this.newAccountData)));
        if (!this.addressConfirmed) {
            const evt = new ShowToastEvent({
                title:      'Customer Billing Information',
                message:    'Please verify that the address selected is confirmed.',
                variant:    'error',
                duration:   20000
            });
            this.dispatchEvent(evt);
            return;
        }
        if (!this.verifyNewAccountData(this.newAccountData)) {
            const evt = new ShowToastEvent({
                title:      'Customer Billing Information',
                message:    'Please confirm that the new address selected is completed.',
                variant:    'error',
                duration:   20000
            });
            this.dispatchEvent(evt);
            return;
        }
        if (!this.verifyZipCode(this.newAccountData.ZIPCode)) {
            const evt = new ShowToastEvent({
                title:      'Customer Billing Information',
                message:    'Please confirm that the Zip Code for the address selected is five digits.',
                variant:    'error',
                duration:   20000
            });
            this.dispatchEvent(evt);
            return;
        }
        const evt = new ShowToastEvent({
            title:      'Customer Billing Information',
            message:    'Other address is being saved.',
            variant:    'success',
            duration:   20000
        });
        this.dispatchEvent(evt);
        if ((typeof this.newAccountData.addressLineTwo !== 'undefined') && (this.newAccountData.addressLineTwo.length !== 0)) {
            this.newAccountData.addressLineTwo = '\n ' + this.newAccountData.addressLineTwo;
        }
        saveNewBillingAddress({opportunityId : this.oppId, dataToSave : [this.newAccountData]})
            .then(result => {
                const evt = new ShowToastEvent({
                    title:      'Customer Billing Information',
                    message:    'Other address saved.',
                    variant:    'success',
                    duration:   20000
                });
                this.dispatchEvent(evt);
                console.log(result);
            })
            .catch(error => {
                const evt = new ShowToastEvent({
                    title:      'Customer Billing Information',
                    message:    'Other address failed to save.',
                    variant:    'error',
                    duration:   20000
                });
                this.dispatchEvent(evt);
                console.log(JSON.parse(JSON.stringify(error)));
                console.log('Error when saving alternate billing address.');
            });
    }

    @wire(getCustomerId,{ recordId: '$oppId', refreshExecute : '$refreshExecute'}) 
        wiredgetCustomerId({ error, data }) { 
            if (data) {
                this.customerId = data;
                console.log('Customer Data::'+this.customerId);
            } else if (error) {  
                this.customerId = null; 
                
            }
    }

    /* accountData = {
        addressLineOne : 'testHook',
        addressLineTwo : 'testHook',
        city : 'testHook',
        state : 'testHook',
        country : 'testHook',
        ZIPCode : 'testHook'
    };
*/

    @wire(getOpportunityData,{opportunityId: '$oppId'})
     wiredgetOpportunityData({error, data}){
        if(data){
            this.BillingContactName = data.End_User__r.Name;
            this.accountData.addressLineOne = data.End_User__r.BillingStreet;
            this.accountData.addressLineTwo = '';
            this.accountData.city = data.End_User__r.BillingCity;
            this.accountData.state = data.End_User__r.BillingState;
            this.accountData.country = data.End_User__r.BillingCountry;
            this.accountData.ZIPCode = data.End_User__r.BillingPostalCode;
            if ((typeof data.End_User__r.ShippingStreet === 'undefined') || (data.End_User__r.ShippingStreet.split('\n ').length === 1)) {
                this.newAccountData.addressLineOne = data.End_User__r.ShippingStreet;
                this.newAccountData.addressLineTwo = '';
            } else {
                this.newAccountData.addressLineOne = data.End_User__r.ShippingStreet.split('\n ')[0];
                this.newAccountData.addressLineTwo = data.End_User__r.ShippingStreet.split('\n ')[1];
            }
            this.newAccountData.city = data.End_User__r.ShippingCity;
            this.newAccountData.state = data.End_User__r.ShippingState;
            if ((typeof data.End_User__r.ShippingCountry === 'undefined') || (data.End_User__r.ShippingCountry === '')) {
                this.newAccountData.country = 'United States';
            } else {
                this.newAccountData.country = data.End_User__r.ShippingCountry;
            }
            this.newAccountData.ZIPCode = data.End_User__r.ShippingPostalCode;
            console.log('BillingContactName Data::'+this.BillingContactName);
        }else{
            console.log('BillingContactName Data::'+error);
        }

     }
    // handle customer billing info change
    handleCustomerBillingChange(event){
        console.log(event.detail.value);
        this.addressConfirmed = false;
        this.customerBillingInfoValue=event.detail.value;
        if(this.customerBillingInfoValue=='provideNewAddress'){
            this.billingAddress=false;
        } else {
            this.billingAddress=true;
        }
        saveBillingPreference({opportunityId : this.oppId, selection : this.billingAddress.toString()})
        .then(result => {
            console.log('Billing Preference saved!');
        }).catch(error => {
            console.log(JSON.parse(JSON.stringify(error)));
        });
    }
}