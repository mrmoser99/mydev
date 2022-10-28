import { LightningElement, api, wire, track } from 'lwc';
import { dispatchPopUpNotification, reduceErrors} from 'c/ldsUtils';
import getDocuments from '@salesforce/apex/ESignInformationController.getPDFs';
import Partner_Portal_URL from '@salesforce/label/c.Partner_Portal_URL';

export default class ESignMasterCmp extends LightningElement {
    @api quoteId;
    @api currentQuoteStage;
    @api opportunityId;
    @api primaryProduct;
    @track documents = [];
    loaded = false;
    Partner_Portal_URL = Partner_Portal_URL;

    /**
     * refresh data in the c-e-sign-information child component when new order is created
     */
    refreshESignInformation() {
        this.template.querySelector('c-e-sign-information').refresh();
    }

    /**
     * show pop up notification with message at the top of parent component
     */
    handleNotificationPopup(event){
        dispatchPopUpNotification(this, event.detail.message, event.detail.variant); 
    }

    /**
     * Get map where document id is a key and document type/title is value and create array with document data.
     * User can download document by clicking on the link
     */
     @wire(getDocuments, {quoteId: '$quoteId'})
     wiredDocuments(result) {
         if (result.data) {
            let dataArr = [];
            Object.entries(JSON.parse(result.data)).forEach(([key, value]) => {
                dataArr.push({
                    id: key,
                    name: value.replace(value.split('-')[0] + '-', ''),
                    type: value.split('-')[0],
                    url: this.Partner_Portal_URL+'sfsites/c/sfc/servlet.shepherd/document/download/' + key 
                });
            });
            this.documents = dataArr.length > 0 ? dataArr : undefined;
            this.loaded = true;
         } else if (result.error) {
            console.error(reduceErrors(error));
            // show pop up notification with error message
            dispatchPopUpNotification(this, reduceErrors(error), 'error');
            this.loaded = true;
         }
     }
}