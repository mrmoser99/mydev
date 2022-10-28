import { LightningElement, track, api } from 'lwc';
import getCustomer from '@salesforce/apex/RESTCalloutHelper.getCustomer';
import getCustomerScreenInformation from '@salesforce/apex/CustomerSetupController.getCustomerScreenInfo';
import { reduceErrors, dispatchPopUpNotification, showPopUpNotification, constants } from 'c/ldsUtils';

export default class CustomerSearchCmp extends LightningElement {
    labels = constants;
    noCustomersFound;
    showResults;
    searchByValue = 'organization-number';
    @track customersData = [];
    @track selectedCustomerData = [];
    searchValue;
    loaded = false;
    customerIndex;
    @api currentStage;
    isCustomerSelected;
    isCustomerNotSelected;
    isNotificationStatic = true;
    _quoteId;
    @track validFrom;
    @track validTo;
    status;
    conditions;
    approvedWithConditions;
    @api disabledDueToUnavailibleProduct;
    

    /** If the customer has already been selected, then customer information is displayed. If not, the search form is displayed. */
    connectedCallback() {
        this.getCustomerScreenInfo();
    }
    
    renderedCallback() {
        this.showMessage();
    }

    @api 
    get quoteId() {
        return this._quoteId;
    }

    set quoteId(value) {
        this._quoteId = value;
        if (this.template.querySelector('c-pop-up-notification-cmp')) {
            this.showMessage();
        }
    }

    set currentStage(value) {
        this.status = value;
        this.getCustomerScreenInfo();
    }

    /** Set key-value pairs for the combobox, in which the identifier type is selected */
    get searchByOptions() {
        return [
            { label: this.labels.Company_ID, value: 'organization-number' }
        ];
    }

    /** Set columns for table with customers data */
    get customersColumns() {
        return [
            { label : this.labels.Company_name, fieldName : "companyName", display : "radio", source : "text", schema : "" , icon : "", objKey : "", editable: false, required: false},
            { label : this.labels.Company_ID, fieldName : "companyId", display : "lwc.output", source : "text", schema : "" , icon : "", objKey : "", editable: false, required: false, class: 'slds-p-right_x-small'},  
            { label : this.labels.Address, fieldName : "companyAddress", display : "lwc.output", source : "text", schema : "" , icon : "", objKey : "", editable: false, required: false, class: 'slds-p-right_x-small'}, 
            { label : this.labels.ZIP_code, fieldName : "companyZipCode", display : "lwc.output", source : "text", schema : "" , icon : "", objKey : "", editable: false, required: false, class: 'slds-p-right_x-small'} 
        ];
    } 

    /** Set columns for table with selected customer data */
    get selectedCustomerColumns() {
        return [
            { label : this.labels.Company_name, fieldName : "companyName", display : "lwc.output", source : "text", schema : "" , icon : "", objKey : "", editable: false, required: false},
            { label : this.labels.Company_ID, fieldName : "companyId", display : "lwc.output", source : "text", schema : "" , icon : "", objKey : "", editable: false, required: false, class: 'slds-p-right_x-small'},  
            { label : this.labels.Address, fieldName : "companyAddress", display : "lwc.output", source : "text", schema : "" , icon : "", objKey : "", editable: false, required: false, class: 'slds-p-right_x-small'}, 
            { label : this.labels.ZIP_code, fieldName : "companyZipCode", display : "lwc.output", source : "text", schema : "" , icon : "", objKey : "", editable: false, required: false, class: 'slds-p-right_x-small'} 
        ];
    }

    /** Handle identifier type changes */
    handleChange(event) {
        this.searchByValue = event.detail.value;
    }

    /** Check if the search field is populated */
    handleSearch() {
        let inputCmp    = this.template.querySelector('lightning-input.search-input');
        let searchValue = inputCmp.value;
        let validity    = !(!searchValue || searchValue.trim().length === 0)

        this.validateInput(
            inputCmp,
            validity,
            this.labels.Complete_this_field
        );

        if (validity) {
            //remove white spaces
            this.searchValue = searchValue.trim();
            this.getCustomersData();
        }
    }

    /** Input field validation 
     * @param inputField - input field for search
     * @param validity - boolean, shows if input value is valid
     * @param message - error message 
    */
    validateInput(inputField, validity, message) {
        if (!validity) {
            // validation error
            inputField.setCustomValidity(message);
        } else {
            // if there was a custom error before, reset it
            inputField.setCustomValidity('');
        }
        inputField.reportValidity();
    }

    /** Show selected customer data */
    @api showSelectedCustomer() {
        this.getCustomerScreenInfo();
    }

    /** Make call to apex controller to get selected customer data by quote id */
    getCustomerScreenInfo() {
        getCustomerScreenInformation({ quoteId: this._quoteId })
            .then(result => {
                let customerData = [];
                let customerInfo = JSON.parse(result);           
                if (customerInfo.End_User__c === undefined) {
                    this.isCustomerSelected = false;
                    this.isCustomerNotSelected = true;
                    this.handleDispatchEvent(false);
                } else {
                    customerData.push({
                        companyId:              customerInfo.End_User__r.External_Identifier__c,
                        companySFDCId:          customerInfo.End_User__c,
                        companyName:            customerInfo.End_User__r.Name,
                        companyLegalName:       customerInfo.End_User__r.Name,
                        companyStreet:          customerInfo.End_User__r.BillingStreet,
                        companyCity:            customerInfo.End_User__r.BillingCity,
                        companyAddress:         customerInfo.End_User__r.BillingStreet + ', ' + customerInfo.End_User__r.BillingCity,
                        companyZipCode:         customerInfo.End_User__r.BillingPostalCode,
                    });
                    this.selectedCustomerData = customerData;
                    this.validFrom = customerInfo.Quotes.records[0].Valid_From__c;
                    this.validTo = customerInfo.Quotes.records[0].Valid_To__c;
                    this.conditions = (customerInfo.Quotes.records[0].Status === 'Approved With Conditions')
                        ? customerInfo.Quotes.records[0].Conditions__c.replace(';', '; ')
                        : undefined;
                    this.isCustomerSelected = true;
                    this.handleDispatchEvent(true);
                    this.isCustomerNotSelected = false;
                }
            })
            .catch(error => {
                dispatchPopUpNotification(
                    this,
                    reduceErrors(error), 
                    'error'
                );
            });
    }

    /** Make call to apex controller (perform REST request) to get customer data by entered parameters */
    getCustomersData() {
        this.loaded = false;
        this.showResults = true;
        getCustomer({ quoteId: this._quoteId, identifier: this.searchValue, identifierType: this.searchByValue })
            .then(result => {
                let customersData = [];
                let resultObject = JSON.parse(result); 
                // if the result contains the key "message", then an error has occurred
                // errors are handled in this block, because the try-catch is used in the apex controller
                if (resultObject.statusCode != 200) {
                    this.noCustomersFound = true;
                    if (resultObject.message != null) {
                        dispatchPopUpNotification(
                            this,
                            resultObject.message, 
                            'error'
                        );
                    } else {
                        dispatchPopUpNotification(
                            this,
                            this.labels.Contact_Admin_Error, 
                            'error'
                        );
                    }
                } else if (resultObject.data != null && resultObject.data.length > 0) {
                    this.noCustomersFound = false;
                    this.handleDispatchEvent(true);
                    resultObject.data.forEach((item, index) => {
                        customersData.push({
                            companyId:              this.searchValue,
                            companySFDCId:          null,
                            companyName:            { label: item.name, value: index },
                            companyLegalName:       item.name,
                            companyStreet:          item.address.street,
                            companyCity:            item.address.city,
                            companyAddress:         item.address.street + ', ' + item.address.city,
                            companyZipCode:         item.address.postalCode,
                            companyData:            item,
                        });
                    });
                // if all request params are correct, but where is no such a customer (empty response)
                } else if (resultObject.data.length === 0) {
                    this.noCustomersFound = true;
                    this.handleDispatchEvent(false);
                    dispatchPopUpNotification(
                        this,
                        this.labels.Customer_has_not_been_found, 
                        'info'
                    )
                }
                this.customersData = customersData;               
                this.loaded = true;
            })
            .catch(error => {
                this.loaded = true;
                this.showResults = false;
                dispatchPopUpNotification(
                    this,
                    reduceErrors(error), 
                    'error'
                );
            });
    }

    handleDispatchEvent(isCustomerSelected){
        const selectEvent = new CustomEvent('customerselect', {
            detail: isCustomerSelected
        });
        this.dispatchEvent(selectEvent);
    }
    
    /** Set customer index from table when user click on radio button */
    handleCustomerSelect(event) {
        this.customerIndex = event.detail;
    }

    /** Send customer data to parent [c-quote-calculator] 
     * @return {} customer info
    */
    @api getCustomer() {
        return (this.selectedCustomerData.length > 0) 
            ? this.selectedCustomerData[0]
            : (this.customerIndex === undefined && this.customersData.length > 0) 
                ? this.customersData[0] 
                : this.customersData[this.customerIndex];
    }

    /**
     * Show fixed notification from this component and its parent [c-quote-calculator] 
     */
    @api showNotification(message, variant) {
        showPopUpNotification(this, message, variant);
    }

    /**
     * Show notification base on Quote status
     */
    showMessage() {
        switch (this.currentStage) {
            case 'Refer':
                this.showNotification(this.labels.manual_Assessment_msg, 'info');
                break;
            case 'Declined':
                this.showNotification(this.labels.credit_has_been_rejected, 'error');
                break;
            case 'Blocked Due To Multiple PG':
                this.showNotification(this.labels.Error_Quote_Is_Blocked, 'error');
                break
            case 'Approved':
                this.showNotification(`${this.labels.Date_of_credit_approval}: ${this.validFrom}. ${this.labels.Credit_expiration_date}: ${this.validTo}`, 'success');
                break;
            default:
                this.template.querySelector('c-pop-up-notification-cmp').hideNotification();
        }
    }

}