/************************************************************************************************************************
 * Change Log:
 *  03/28/2023 - MRM Create Action
 */
import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import setPartnerUser from "@salesforce/apex/UserUtils.setPartnerUser"; 
import { NavigationMixin } from 'lightning/navigation';

export default class SetPartnerUserScreenAction extends NavigationMixin(LightningElement) {

    @api recordId;



    @api invoke() {
        
        console.log('record id is: ' + this.recordId);

        setPartnerUser({'contactId' : this.recordId})
        .then(result => {
            const event = new ShowToastEvent({
                title: 'Success',
                message: 'Your portal user is all set! Proceed with internal portal process.',
                variant: 'success'
            });
            this.dispatchEvent(event);

            console.log('ready to navigate');

            this[NavigationMixin.Navigate]
                ({
                    type: 'standard__webPage',
                    attributes: {
                        url: window.location.origin + '/lightning/o/Recent_Partner_User__c/list'
                    }
                });  
        })
        .catch(error => {
            console.log('error is: ' + error) ;
             
            const event = new ShowToastEvent({
                title: 'Error',
                message: error.body.message,
                variant: 'error'
            });
            this.dispatchEvent(event);
             
        });
                             
        
    }

}