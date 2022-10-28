import { LightningElement, track } from 'lwc';
import getESignInformation from '@salesforce/apex/ESignInformationController.getEsignInfoString';
import getStandardAuthCustomMeta from '@salesforce/apex/ESignInformationController.getStandardAuthCustomMeta';
import { reduceErrors, getUrlParamValue, showPopUpNotification, constants, esignStatuses } from 'c/ldsUtils';

export default class EIdent extends LightningElement {

    labels = constants;
    eSignStatuses = esignStatuses;
    orderId;
    orderIdParamName = 'orderId';
    identificationRequest;
    eIdentUrl;
    clientId;
    response_type='code';
    redirect_uri;
    scope;
    state;
    nonce;
    eSingStatus;
    isNotificationStatic = true;

    connectedCallback() {
        // get order id from URL
        this.orderId = getUrlParamValue(window.location.href, this.orderIdParamName);
        this.getESignStatus();
    }

    /**
     * Check order status and display identification page if order status is valid
     */
    getESignStatus() {
        getESignInformation({eSignInfoId: this.orderId})
        .then(result => {
            this.eSingStatus = JSON.parse(result).Status__c;
            this.showContent(); 
        })
        .catch(error => {
            console.error(reduceErrors(error));
            showPopUpNotification(this, this.labels.Contact_Admin_Error, 'error');
        })
    }

    /**
     * Display content base on order status
     */
    showContent() {
        switch (this.eSingStatus) {
            case this.eSignStatuses.New:
            case this.eSignStatuses.Active:
                this.getAuthorizationParams();      
                break;
            case this.eSignStatuses.CancelledByMerchant:
            case this.eSignStatuses.Expired:
            case this.eSignStatuses.Failed:
            case this.eSignStatuses.RejectedBySigner:
                showPopUpNotification(this, this.labels.E_Sign_Link_Has_Expired, 'error');    
                break;
            case this.eSignStatuses.Complete:
                showPopUpNotification(this, this.labels.E_Sign_Has_Been_Completed, 'info');    
                break;
        }
    }

    /**
     * Form Identification request which is used in the iframe
     */
    setIdentificationRequest() {
        this.setParams();
        this.identificationRequest = `${this.eIdentUrl}?client_id=${this.clientId}&response_type=${this.response_type}&redirect_uri=${this.redirect_uri}&scope=${this.scope}&state=${this.state}&nonce=${this.nonce}&​additional_info=${this.orderId}`;
        this.identificationRequest = this.identificationRequest.replace('/\p{C}+/u', '');
        
        window.location.href = this.identificationRequest;
    }

    /**
     * Set params for Identification request which should be random and unique
     */
    setParams() {
        this.state = new Date().toISOString() + this.orderId;
        this.nonce = 'SFDC' + this.orderId + '-' + Math.floor(Math.random() * 10000000) + Math.random().toString(36).substring(6);   
    }

    /**
     *get the authorization details from custom metadata type
     */
    getAuthorizationParams(){
        getStandardAuthCustomMeta({recordName : 'E_Sign_Creds'})
            .then(result => {
                if(result){
                    this.eIdentUrl = result.Authorization_URL__c;
                    this.clientId = result.Client_Id__c;
                    this.scope = result.Scope__c;
                    this.redirect_uri = result.Redirect_URI__c;
                    this.setIdentificationRequest(); 
                }                                            
            })
            .catch(error => {
                console.error(reduceErrors(error));
            })  
    }
}