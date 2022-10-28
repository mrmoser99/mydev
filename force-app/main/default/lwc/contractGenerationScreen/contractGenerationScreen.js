import { LightningElement, track,api } from 'lwc';
import getCustomerDetails from '@salesforce/apex/ContractGenerationController.getCustomerDetails';
import { constants,insuranceDispTranslated, quoteStatuses } from 'c/ldsUtils';

export default class ContractGenerationScreen extends LightningElement {
    labels = constants;
    quoteStatuses = quoteStatuses;
    insuranceDispTranslated = insuranceDispTranslated;
    @api customerData;
    @api quoteId;
    @api customerInfo = [];
    @track specialTermsCondtion = [];
    isSpecialTnCExist = false;
    customerResult;
    @api insuranceRadioValue;
    insuranceDiplayOptions = [];
    @api isDisabled = false;
    @api isLoading = false;
    @api currentStage;
    gaurantorExist = true;
    approvedCondition = false;
    downpaymentExist = false;
    termValueExist = false;
    gaurantorExistSen;
    approvedConditionSen;
    downpaymentExistSen;
    termValueExistSen;
    @track approvedWithCondition = [];    

     // Set columns for table with Special T&C 
    get specialTncColumns() {
        return [
            { label : '', fieldName : "specialtncCheckbox", display : "checkbox", source : "checkbox", schema : "" , icon : "", objKey : "", editable: false, required: false},
            { label : '', fieldName : "specialTncName", display : "lwc.output", source : "text", schema : "" , icon : "", objKey : "", editable: false, required: false, class: 'slds-p-right_x-small'},  
         ];
    } 

    connectedCallback(){
       this.getCustomerDetails(this.quoteId);
    }

    /**Get the customer details */
    getCustomerDetails(quoteId){
        this.isLoading = true;
        //apex callout
        getCustomerDetails({
            quoteId : quoteId
        })
        .then(result => { 
            if(result){
                this.isLoading = false;
                this.customerResult = JSON.parse(result); 
               //forming the insurance display options
                let insuranceOptionsList = !this.isNullOrZeroOrUndefined(this.customerResult.insuranceDisplayOptions) ? this.customerResult.insuranceDisplayOptions.split(';') : [];
                for (let i = 0; i < insuranceOptionsList.length; i++) {                  
                    this.insuranceDiplayOptions.push({                         
                        label : this.insuranceDispTranslated[insuranceOptionsList[i]],
                        value: insuranceOptionsList[i]
                    });                 
                }
                this.insuranceDiplayOptions.reverse();                
                this.insuranceRadioValue = !this.isNullOrZeroOrUndefined(this.customerResult.insuranceCondition) ? this.customerResult.insuranceCondition : this.customerResult.defaultInsurance;

                this.customerInfo = {
                    companySFDCId: this.customerResult.accountId,
                    companyId: this.customerResult.companyId,
                    companyName: this.customerResult.companyLegalName,
                    companyAddress: this.customerResult.companyAddress,
                    companyZipCode: this.customerResult.companyZipCode,
                    contactName: this.customerResult.contactName,
                    contactEmail: this.customerResult.contactEmail,
                    contactPhoneNumber: this.customerResult.contactPhoneNumber,
                    contactStreet: this.customerResult.contactStreet,
                    contactCity: this.customerResult.contactCity,
                    contactZipCode: this.customerResult.contactZipCode,
                    contactRefernce: this.customerResult.contactReference,
                };

                if(this.customerResult.Status == 'Approved With Conditions'){
                    this.approvedCondition = true;
                    this.approvedConditionSen = `${this.labels.Please_note_that} ${this.customerResult.opportunityName} ${this.labels.was_accepted_with_below_credit_condition}`;
                }
                if(this.customerResult.typeDownpayment != null){
                    this.downpaymentExistSen = this.customerResult.typeDownpayment + ' ' + this.customerResult.valueDownpayment  + ' ' +  this.labels.Current_Currency  + ' ' + this.labels.need_to_be_paid_before_the_Contract_starts;
                    this.approvedWithCondition.push(this.downpaymentExistSen);
                }
                if(this.customerResult.valueTerm != null){
                    this.termValueExistSen =  this.labels.New_term + ' ' + this.customerResult.valueTerm  + ' ' +  this.labels.has_been_applied_to_the_Contract;
                    this.approvedWithCondition.push(this.termValueExistSen);
                }
                if(this.customerResult.relatedPartyList.length > 0){
                    this.gaurantorExistSen =  this.labels.Guarantor_Guarantors_needed;
                    this.approvedWithCondition.push(this.gaurantorExistSen);
                }
               
                this.customerResult.offerSpTnCList.forEach(item => {
                    this.specialTermsCondtion.push({
                        'Name' : item.Special_Terms_and_Conditions__r.Name,
                        'Category': item.Special_Terms_and_Conditions__r.Category__c,
                        'recordId': item.Special_Terms_and_Conditions__r.Id,
                        // Check quote status and display options applicable for offer if documents have not been generated yet
                        // Otherwise display options which already have been selected and saved for current quote
                        'isChecked': (this.currentStage === this.quoteStatuses.Approved || this.currentStage === this.quoteStatuses.ApprovedWithConditions)
                                        ? (item.Special_Terms_and_Conditions__r.Category__c === 'Mandatory') 
                                            ? true
                                            : false
                                        : (this.customerResult.quoteSTnCIds.includes(item.Special_Terms_and_Conditions__r.Id))
                                            ? true
                                            : false,
                        'isCheckboxDisabled': (item.Special_Terms_and_Conditions__r.Category__c === 'Mandatory' || this.isDisabled) ? true : false,
                    });
                    this.isSpecialTnCExist = true;
                }); 
            }          
        })
        .catch(error => {
            this.isLoading = false;
           
        });
    }

    /**
     * To get the radio button value on change of the selection
     */
     handleInsurncRadioChange(event){
        this.insuranceRadioValue = event.target.value;
    }

    handleInsuranceSectionToggle(event) {
        const openSections = event.detail.openSections;
    }

    /**method to find if a value is valid or not */
    isNullOrZeroOrUndefined(value) {
        return value == null || value == undefined || value == 0 || value == '';
    }

    /**
     * Name: checkIsNumber
     * Purpose: to validate only numbers are input
     */
    checkIsNumber(evt){       
        let charCode = evt.keyCode;
        if (charCode > 31 && (charCode < 48 || charCode > 57)) {
            evt.preventDefault();
            return false;
        }
        return true;
    }

    /**Get the customer detail from UI and pass to parent component[quoteCalculator] */
    @api getContactAndDeliveryDetails(){
      
        const contactNameValue = this.template.querySelector('lightning-input.input-name').value;
        const contactEmailValue = this.template.querySelector('lightning-input.input-email').value;
        const contactPhoneValue = this.template.querySelector('lightning-input.input-phone').value;
        const contactStreetValue = this.template.querySelector('lightning-input.input-street').value;
        const contactCityValue = this.template.querySelector('lightning-input.input-city').value;
        const contactZipCodeValue = this.template.querySelector('lightning-input.input-zip-code').value;
        const contactReferenceValue = this.template.querySelector('lightning-input.input-reference').value;
        
        const contactData = {
            'contactName' : contactNameValue,
            'contactEmail' : contactEmailValue,
            'contactPhone' : contactPhoneValue ,
            'contactStreet' : contactStreetValue,
            'contactCity' : contactCityValue,
            'contactZipCode' : contactZipCodeValue,
            'contactReference' : contactReferenceValue,
            'accountId' : this.customerResult.accountId,
            'quoteId' : this.quoteId,
            'insuranceCondition' : this.insuranceRadioValue           
        }
        return contactData;

    }

    /**
     * Updated object with Special Terms and Condtion data if checkbox was checked/unchecked
     */
    changeSpecialTnC(event) {
        this.specialTermsCondtion.forEach(item => {
            if (item.recordId === event.currentTarget.value) {
                item.isChecked = event.currentTarget.checked
            }
        });
    }

    /**
     * Send object with Special Terms and Condtion data to parent QuoteCalculator component
     */
    @api getSpecialTermsCondtion() {
        return this.specialTermsCondtion;
    }

}