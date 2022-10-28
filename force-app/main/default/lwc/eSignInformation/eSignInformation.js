import { LightningElement, api, wire, track } from 'lwc';
import getESignData from '@salesforce/apex/ESignInformationController.getESignInfomation';
import { reduceErrors, dispatchPopUpNotification, constants, esignStatuses, smartcommDocTypeEN, quoteStatuses } from 'c/ldsUtils';
import { refreshApex } from '@salesforce/apex';
import cancelSendingForSignture from '@salesforce/apex/ESignInformationController.cancelSignture';

export default class ESignInformation extends LightningElement {
    @api quoteId;
    @api currentQuoteStage;
    @track data = [];
    loaded = false;
    stringData;
    showModalToCancel;
    recordId;

    esignStatuses = esignStatuses;
    quoteStatuses = quoteStatuses;
    smartcommDocTypeEN = smartcommDocTypeEN;
    labels = constants;

    /**
     * Get orders info
     */
    @wire(getESignData, {qouteId: '$quoteId'})
    wiredData(result) {
        this.stringData = result;
        if (result.data) {
            // this object groups orders by document type
            let eSignInfoByDocumentType = {};
            JSON.parse(result.data).forEach(item => {
                let type = this.smartcommDocTypeEN[item.Document_Type__c];

                // add new key (type) if there is no such document type
                // value is an array with order info
                if (eSignInfoByDocumentType[type] === undefined) {
                    eSignInfoByDocumentType[type] = [];
                }

                //get some properties according to the order status
                let eSignInfo = this.getESignItemInfo(item);

                // add order info in array for particular document type
                eSignInfoByDocumentType[type].push({
                    id: item.Id,
                    status: eSignInfo.status,
                    signerName: item.Signer_Name__c,
                    ssn: item.SSN_Number__c,
                    email: item.Customer_Email__c,
                    dateTime: eSignInfo.dateTime,
                    class: eSignInfo.class,
                    iconName: eSignInfo.iconName,
                    closeButton: eSignInfo.closeButton,
                });
            });

            // create array from eSignInfoByDocumentType object to iterate it in the component
            let dataArr = [];
            Object.entries(eSignInfoByDocumentType).forEach(([key, value]) => {
                dataArr.push({
                    type: key,
                    documents: value 
                });
            });

            this.data = dataArr.length > 0 ? dataArr : undefined;
            this.loaded = true;
        } else if (result.error) {
            this.data = undefined;
            console.error(reduceErrors(result.error));
            // show pop up notification with error message
            dispatchPopUpNotification(this, this.labels.Contact_Admin_Error, 'error');
            this.loaded = true;
        }
    }

    /**
     * get properties according to the order status
     */
    getESignItemInfo(item) {
        let itemInfo = {};

        switch (item.Status__c) {
            case this.esignStatuses.New:
            case this.esignStatuses.Active:
                itemInfo.status = this.labels.Sent_For_Signature_Order_Status;
                itemInfo.class = 'unsigned e-sign-info';
                itemInfo.iconName = 'utility:forward';
                itemInfo.closeButton = (this.currentQuoteStage === this.quoteStatuses.ReviewCompleted) ? false : true;
                itemInfo.dateTime = Date.parse(item.First_Email_Sending_Date__c);
                break;
            case this.esignStatuses.Pending_Contract:
                itemInfo.status = this.labels.Pending_Contract_Signature;
                itemInfo.class = 'unsigned e-sign-info';
                itemInfo.iconName = 'utility:clock';
                itemInfo.closeButton = (this.currentQuoteStage === this.quoteStatuses.ReviewCompleted) ? false : true;
                itemInfo.dateTime = Date.parse(item.CreatedDate);
                break;
            case this.esignStatuses.Complete:
                itemInfo.status = this.labels.Signed_Order_Status;
                itemInfo.class = 'signed e-sign-info';
                itemInfo.iconName = 'utility:check';
                itemInfo.closeButton = false;
                itemInfo.dateTime = Date.parse(item.Date_Of_Signing__c);
                break;
            case this.esignStatuses.CancelledByMerchant:
            case this.esignStatuses.Expired:
            case this.esignStatuses.Failed:
            case this.esignStatuses.RejectedBySigner:
                itemInfo.status = this.labels.Cancelled_Order_Status;
                itemInfo.class = 'cancelled e-sign-info';
                itemInfo.iconName = 'utility:cancel_file_request';
                itemInfo.closeButton = false;
                itemInfo.dateTime = Date.parse(item.LastModifiedDate);
                break;
            default:
                break;
        }
        
        return itemInfo;
    }

    /**
     * Show modal window with confirmation to cancel order
     */
    handleCancelSignature(recordId) {
        this.showModalToCancel = true;
        this.recordId = recordId;
    }

    /**
     * Close modal window with confirmation to cancel order
     */
    closeModal() {
        this.showModalToCancel = false;
        this.recordId = undefined;
    }

    /**
     * Cancel order in "New", "Pending Contract" and "Active" status
     */
    confirmCancelletion() {
        this.showModalToCancel = false;
        this.loaded = false;
        cancelSendingForSignture({eSignInfoId: this.recordId})
        .then(data => {
            // refresh data
            this.refresh();
            let response = JSON.parse(data);
            if (response['Error message'] != null) {
                console.error(response['Error message']);
                // show pop up notification with error message
                dispatchPopUpNotification(this, this.labels.Contact_Admin_Error, 'error');
            } else if (response['Success message'] != null) {
                // show pop up notification with success message
                dispatchPopUpNotification(this, response['Success message'], 'success');
            } else if (response['Warning message'] != null) {
                // show pop up notification with success message
                dispatchPopUpNotification(this, response['Warning message'], 'error');
            }
            this.loaded = true;
            this.recordId = undefined;
        })
        .catch(error => {
            console.error(reduceErrors(error));
            // show pop up notification with error message
            dispatchPopUpNotification(this, this.labels.Contact_Admin_Error, 'error');
            this.loaded = true;
            this.recordId = undefined;
        })
    }

    /**
     * Show expanded view for order
     */
    handleExpandedView(event) {
        let cmp = event.currentTarget;

        // check if cancel button has been clicked
        if (event.target.classList.contains('slds-icon-utility-close')) {
            // cancel order
            this.handleCancelSignature(cmp.dataset.id);   
        } else {
            // show expanded view
            cmp.classList.toggle('expanded-view');
        }
    }

    /**
     * refresh data after adding/deleting order
     */
    @api
    refresh() {
        refreshApex(this.stringData);
    }
}