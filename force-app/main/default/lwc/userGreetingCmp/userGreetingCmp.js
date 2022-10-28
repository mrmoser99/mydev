import { LightningElement, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import Id from '@salesforce/user/Id';
import { constants } from 'c/ldsUtils';

export default class UserGreetingCmp extends LightningElement {

    labels = constants;
    userName;

    /** Get user full name by user Id */
    @wire(getRecord, { recordId: Id, fields: ['User.Name'] })
    userData({data}) {
        if (data) {
            this.userName = data.fields.Name.value;
        } 
    }
}