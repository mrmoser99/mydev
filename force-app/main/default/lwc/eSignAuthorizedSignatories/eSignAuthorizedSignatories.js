import { LightningElement, api, wire, track } from 'lwc';
import getAuthorizedSignatories from '@salesforce/apex/ESignInformationController.getAuthorizedSignatoriesInfo';
import { reduceErrors, dispatchPopUpNotification, constants } from 'c/ldsUtils';

export default class ESignAuthorizedSignatories extends LightningElement {
    @api quoteId;
    @api opportunityId;
    showSignatories = false;
    @track data = [];
    loaded = false;
    signingInfo;

    labels = constants;

    /**
     * set columns property for Authorized Signatories table 
     */ 
    columns = [
        { label : this.labels.Name, fieldName : "signerName", display : "lwc.output", source : "text", icon : "action:call", objKey : "Contact", editable: false, required: false },       
        { label : this.labels.ssn, fieldName : "ssn", display : "lwc.output", source : "text", icon : "action:call", objKey : "Contact", editable: false, required: false },     
        { label : this.labels.Role, fieldName : "role", display : "lwc.output", source : "text", icon : "action:call", objKey : "Contact", editable: false, required: false },   
    ]

    /**
     * get authorized signatories (contact) for customer
     */
    @wire(getAuthorizedSignatories, {opportunityId: '$opportunityId'})
    wiredData(result) {
        if (result.data) {
            let data = [];
            JSON.parse(result.data).forEach(item => {
                this.signingInfo = item.Authorized_signatory_Text__c;
                data.push({
                    id: item.Id,
                    signerName: item.Name,
                    ssn: item.External_ID__c,
                    role: item.Title,
                });
            });

            this.data = data.length > 0 ? data : undefined;
            this.loaded = true;
        } else if (result.error) {
            this.data = undefined;
            console.error(reduceErrors(result.error));
            // show pop up notification with error message
            dispatchPopUpNotification(this, reduceErrors(error), 'error');
            this.loaded = true;
        }
    }

    /**
     * switch Signatories data from showing to hiding
     */
    handleShowSignatories() {
        this.showSignatories = !this.showSignatories;
    }

}