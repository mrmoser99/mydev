/*This javascript call the Apex class salesforce/apex/getContractInfolease
to fetch the contract Information and display on screen
Author - Geetha Bharadwaj
Date - 2021/02/05*/
import { LightningElement,track, api, wire } from 'lwc';
import getwrapperData from '@salesforce/apex/GetContractInfolease.getContract';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class ShowContractInfo extends LightningElement {
    @api recordId;
    @track data = [];
    @track customerName= '';
    @api loader =false;
 @track apiName= 'getContract';
  connectedCallback(){
        this.loader = true;
        getwrapperData({caseId:this.recordId}).then(result =>{
if(result){
    this.data = result;
    if(this.data[0].statusMessage == 'Failure'){
        const evt = new ShowToastEvent({
            title: 'Info',
            message: 'The contract information for this particular contract is not available in Back Office system - Please try again or contact your System Admin',
            variant: 'info',
            duration:10000,
        });
        this.dispatchEvent(evt);
    }else if(this.data[0].statusMessage == 'ServerDown'){
        const evt = new ShowToastEvent({
            title: 'info',
            message: 'Server is Down.Please try again after sometime. If the issue still persists please contact your System Admin',
            variant: 'info',

           
        });
        this.dispatchEvent(evt);
    }
     else if(this.data[0].statusMessage == 'Success'){
       console.log('Success');   
    }
    this.loader = false;

}

        })
        .catch(error =>{
            this.error =error;
            this.loader = false;
        })
    }
}