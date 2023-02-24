import { LightningElement, api, wire} from 'lwc';
import {getRecord, getFieldValue} from 'lightning/uiRecordApi'; 
import ACC_TYPE from '@salesforce/schema/Account.Type';
import ACC_PHONE from '@salesforce/schema/Account.Phone';
import ACC_INDUSTRY from '@salesforce/schema/Account.Industry';

const fields = [ACC_TYPE, ACC_PHONE, ACC_INDUSTRY];



export default class partnerOBAccountHeader extends LightningElement {

@api accountid;
@wire(getRecord, {recordId: "$accountid",fields })
account;

get type(){
    return getFieldValue(this.account.data, ACC_TYPE);
}

get phone(){
    return getFieldValue(this.account.data, ACC_PHONE);
}

get industry(){
    return getFieldValue(this.account.data, ACC_INDUSTRY);
}

}