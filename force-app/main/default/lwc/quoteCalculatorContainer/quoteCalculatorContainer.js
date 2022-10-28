import { LightningElement, api, wire } from 'lwc';
import customCSS from '@salesforce/resourceUrl/nordics_styles';
import { loadStyle } from 'lightning/platformResourceLoader';
import { getRecord } from 'lightning/uiRecordApi';

const fields = ['Opportunity.OwnerId'];
const userFields = ['User.FirstName', 'User.LastName', 'User.Contact.Account.Name'];

export default class QuoteCalculatorContainer extends LightningElement {
    @api selectedUserId;
    @api recordId; // opportunity recor id (if component is opened from record page)
    showDealPage;
    partnerInfo;

    connectedCallback(){
        // if component is opened from flow and doesn't have record id
        if (this.recordId === undefined) {
            this.showDealPage = true;
        }
        // download css-styles from static resources
        Promise.all([
            loadStyle(this, customCSS)
            .catch(error => {console.error('Error: ' + error);})
        ]);
    }

    // get owner id if it's record page
    @wire(getRecord, {recordId: '$recordId', fields: fields})
    opportunityRecord({ error, data }) {
        if (data) {
            this.selectedUserId = data.fields.OwnerId.value;
            this.showDealPage = true;
        }
    }

    // get partner info
    @wire(getRecord, {recordId: '$selectedUserId', fields: userFields})
    userRecord({ error, data }) {
        if (data) {
            this.partnerInfo = {
                user: `${data.fields.FirstName.value} ${data.fields.LastName.value}`,
                name: data.fields.Contact.value.fields.Account.value.fields.Name.value
            };
        }
    }
}