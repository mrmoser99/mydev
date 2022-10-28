//DLL on Demand - Footer used across all the pages
//PBI:633819 version1: Geetha Bharadwaj

import { LightningElement, api,track } from 'lwc';
import DLL_LOGO from '@salesforce/resourceUrl/DLL_Logo_Blue';
import FACEBOOK_LOGO from '@salesforce/resourceUrl/facebook_logo';
import TWITTER_LOGO from '@salesforce/resourceUrl/twitter_logo';
import LINKEDIN_LOGO from '@salesforce/resourceUrl/linkedIn_logo';

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