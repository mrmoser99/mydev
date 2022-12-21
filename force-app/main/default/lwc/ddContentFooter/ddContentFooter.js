//DLL on Demand - Footer used across all the pages
//PBI:633819 version1: Geetha Bharadwaj
//PBI:779222 version2: Vinicio Ramos - As a portal user I need to know how I can contact DLL for support.

import { LightningElement,wire, api,track } from 'lwc';
import DLL_LOGO from '@salesforce/resourceUrl/DLL_Logo_Blue';
import FACEBOOK_LOGO from '@salesforce/resourceUrl/facebook_logo';
import TWITTER_LOGO from '@salesforce/resourceUrl/twitter_logo';
import LINKEDIN_LOGO from '@salesforce/resourceUrl/linkedIn_logo';
import getContact from '@salesforce/apex/ddContentFooterController.getContactList';
import uId from '@salesforce/user/Id';

export default class DllOnDemandFooter extends LightningElement {
    @api logoUrl;
    @api dateRangeString;
    @track facebooklogo = FACEBOOK_LOGO;
    @track dlllogo = DLL_LOGO;
    @track twitterlogo = TWITTER_LOGO;
    @track linkedinlogo = LINKEDIN_LOGO;
    @api dynamicFooter;
    @api iswelcomescreen;
    @track welcomeFooterCss;
    contactSupport;
    @api contactPhone;
    @api contactEmail;
    
    @wire(getContact, { userId: uId }) 
    wiredGetContact({ error, data}) {
        if (data) {            
            this.contactSupport = data;
            this.contactPhone = this.contactSupport[0].Phone__c;
            this.contactEmail = this.contactSupport[0].Email__c;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.contactSupport = undefined;
        }
    }
  
    connectedCallback() {
        console.log(this.dateRangeString);    
        console.log(this.dynamicFooter)
        if(this.dynamicFooter == 'welcomePageFooter') {
            console.log('Inside If');
            this.welcomeFooterCss = 'slds-grid slds-wrap footerWidthWelcome';
            // this.welcomeFooterCss = 'slds-grid slds-wrap footerWidth';
        } else {
            this.welcomeFooterCss = 'slds-grid slds-wrap footerWidth';
        }
        console.log('FOOTER'+ this.welcomeFooterCss);
    }

    get logo() {
        return `${DLL_LOGO}/${this.logoUrl}`;
    }

    get logo() {
        return `${FACEBOOK_LOGO}/${this.logoUrl}`;
    }

    get logo() {
        return `${TWITTER_LOGO}/${this.logoUrl}`;
    }

    get logo() {
        return `${LINKEDIN_LOGO}/${this.logoUrl}`;
    }

    get dateRange() {
        console.log('DATE' + this.dateRangeString);
        return this.dateRangeString;
    }
}