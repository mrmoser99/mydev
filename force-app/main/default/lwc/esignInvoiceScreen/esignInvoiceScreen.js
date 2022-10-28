import { LightningElement,track } from 'lwc';
import { reduceErrors, showPopUpNotification,getUrlParamValue,constants,smartcommDocType } from 'c/ldsUtils';
import doSaveInvoiceData from '@salesforce/apex/ESignInformationController.doSaveInvoiceData';
import getESignInformation from '@salesforce/apex/ESignInformationController.getEsignInfoString'; 
import submitAppfromInvoiceSrc from '@salesforce/apex/SubmitApplicationHelper.submitAppfromInvoiceSrc';
import { NavigationMixin } from 'lightning/navigation';

export default class EsignInvoiceScreen extends NavigationMixin(LightningElement) {
    labels = constants;
    smartcommDocType = smartcommDocType;
    invoiceTypeVal = '';
    @track invoiceScreenFields = [];
    showEdiSection = false;
    showPdfSection = false;
    showLetterSection = false;
    validity_All = true;
    isLoading = false;
    orderId = '';
    signUrl = '';
    @track isUBO = false;

    get invoiceTypeOptions(){
        return [
            { label: this.labels.EDI, value: 'EDI' },
            { label: this.labels.PDF, value: 'PDF' },
            { label: this.labels.Paper_Invoice, value: 'Letter' },
        ];
    }

    connectedCallback(){
       
        document.title = "Esign";
        //get data onload
        this.orderId = getUrlParamValue(window.location.href, 'orderId');
        this.signUrl = getUrlParamValue(window.location.href, 'signUrl');
        this.isUBO = getUrlParamValue(window.location.href, 'isUBO');
        this.showInvoiceDetailsOnLoad(this.orderId); //onload of page
    }

    handleInvoiceTypeChange(event){
        this.invoiceTypeVal = event.detail.value;
        this.showPageSection(this.invoiceTypeVal);
    }

    showPageSection(invoiceTypeVal){

        if(invoiceTypeVal === 'EDI'){
            this.showEdiSection = true;
            this.showPdfSection = false;
            this.showLetterSection = false;
        }else if(invoiceTypeVal === 'PDF'){
            this.showEdiSection = false;
            this.showPdfSection = true;
            this.showLetterSection = false;
        }else if(invoiceTypeVal === 'Letter'){
            this.showEdiSection = false;
            this.showPdfSection = false;
            this.showLetterSection = true;
        }
    }

    handlePreviousStep(){        
        this.backToAmlScreen();
    }

    backToAmlScreen(){
        let amlPage = {
            type: 'standard__webPage',
            attributes: {     
                url: this.labels.Public_Community_URL + 'aml-screen?signUrl='+encodeURIComponent(this.signUrl) +'&orderId='+this.orderId+'&fromInvPage=true'
            }
        }
       
        this[NavigationMixin.Navigate](amlPage);
    }

    /**
     * Redirect user to sign document page
     */
    redirectToSigningScreen(signUrl){ //iFrame_URL__c
        
        let pageForSigning = {
            type: 'standard__webPage',
            attributes: {
                url: this.labels.Public_Community_URL + 'esigning-page?signUrl=' + encodeURIComponent(signUrl)
            }
        }

        this[NavigationMixin.Navigate](pageForSigning);
    }

    showInvoiceDetailsOnLoad(orderId){
        //call to apex on page load
        getESignInformation({eSignInfoId: this.orderId}) 
        .then(result => {
            this.isLoading = false;   
            let data = JSON.parse(result);
            if(!this.isNullOrZeroOrUndefined(data)){
                this.invoiceTypeVal = data?.Opportunity__r?.End_User__r?.Invoice_Type__c;
                this.showPageSection(this.invoiceTypeVal);
                //if sign url is blank, update with the iframe url
                this.signUrl = this.isNullOrZeroOrUndefined(this.signUrl) ? data.iFrame_URL__c : this.signUrl;
                
                this.invoiceScreenFields = {
                    'pepolId' : data?.Opportunity__r?.End_User__r?.People_ID__c,
                    'ediReference' : data?.Quote__r.Reference__c,
                    'pdfReference':data?.Quote__r.Reference__c,
                    'letterReference' : data?.Quote__r.Reference__c,
                     'pdfEmail' : data?.Opportunity__r?.End_User__r?.Email_Invoice__c,
                    'letterPoNum' : data?.Opportunity__r?.End_User__r?.ShippingPostalCode,
                    'letterAdresBox' : data?.Opportunity__r?.End_User__r?.ShippingStreet,
                    'letterCity' : data?.Opportunity__r?.End_User__r?.ShippingCity,
                    'letterCountry' : data?.Opportunity__r?.End_User__r?.ShippingCountry,
                    'letterCoName' : data?.Opportunity__r?.End_User__r?.C_O_Name__c,
                    'orderId' :this.orderId
                }
            }        
           
        })
        .catch(error => {
            this.isLoading = false;
            console.error(reduceErrors(error));
            showPopUpNotification(this, this.labels.Contact_Admin_Error, 'error');
        })

    }

    //generate the country picklist
    get letterCountryOptions(){
        let countryOptions = [];
        let countriesSplit = this.labels.Invoice_Page_Countries.split(';');
        countriesSplit.forEach(country=>{        
            countryOptions.push({ label: country, value: country});           
        })
        return countryOptions;
    }


    //find the correct Pepolid format
    //Verification on Peppol-ID field:
    //It should start with 0007: followed by 10 numbers or start with 0088: followed by 13 numbers. All other combinations should receive an error message
    isInCorrectPepolIdFromat(pepolId){
        if(!this.isNullOrZeroOrUndefined(pepolId) && ((pepolId.startsWith('0007') && pepolId.length === 14) || (pepolId.startsWith('0088') && pepolId.length === 17))){
            return false;
        }
        return true;
    }

    //do submit app callout & saves the details in customer account
    handleNextStep(){
       
        this.validity_All = true;
        this.isLoading = true; 
        if(this.isNullOrZeroOrUndefined(this.invoiceTypeVal)){
            this.validity_All = false;
            this.validateInput(
                this.template.querySelector('lightning-combobox.picklist-invoice-type'),
                this.validity_All,
                this.labels.Please_select_Invoice_type
            );
        }else{
            this.validateInput(
                this.template.querySelector('lightning-combobox.picklist-invoice-type'),
                true,
                ''
            );
        }
        
        //EDI 
        if(this.showEdiSection){     
            const pepolIdValue = this.template.querySelector('lightning-input.input-pepolId').value;
            const ediRefrenceValue = this.template.querySelector('lightning-input.input-ediReference').value;
            this.validity_All = !(this.isNullOrZeroOrUndefined(pepolIdValue) || this.isInCorrectPepolIdFromat(pepolIdValue));
            this.validateInput(
                this.template.querySelector('lightning-input.input-pepolId'),
                this.validity_All,
                this.labels.Please_enter_valid_PepolId 
            );
            if(this.validity_All){ 
                this.invoiceScreenFields = {
                    'invoiceType' : this.invoiceTypeVal,
                    'pepolIdValue' : pepolIdValue,
                    'ediRefrenceValue' : ediRefrenceValue,
                    'orderId' :this.orderId
                }
            }
        }else if(this.showPdfSection){ //PDF
            const pdfEmailValue = this.template.querySelector('lightning-input.input-pdfEmail').value;
            const pdfReferenceValue = this.template.querySelector('lightning-input.input-pdfReference').value;
            let mailformat = /^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$/;
            this.validity_All = !(!pdfEmailValue || pdfEmailValue.trim().length === 0 || !pdfEmailValue.match(mailformat));
            this.validateInput(
                this.template.querySelector('lightning-input.input-pdfEmail'),
                this.validity_All,
                this.labels.Error_Enter_Valid_Email
            ); 
            if(this.validity_All){ 
                this.invoiceScreenFields = {
                    'invoiceType' : this.invoiceTypeVal,
                    'pdfEmailValue' : pdfEmailValue,
                    'pdfReferenceValue' : pdfReferenceValue,
                    'orderId' :this.orderId
                }
            }
            
        }else if(this.showLetterSection){ //Letter
            
            const letterCoNameValue = this.template.querySelector('lightning-input.input-letterCoName').value;
            const letterAdresValue = this.template.querySelector('lightning-input.input-letterAdres').value;
            const letterPoNumValue = this.template.querySelector('lightning-input.input-letterPoNum').value;
            const letterCityValue = this.template.querySelector('lightning-input.input-letterCity').value;
            const letterCountryValue = this.template.querySelector('lightning-combobox.picklist-letterCountry').value;
            const letterReferenceValue = this.template.querySelector('lightning-input.input-letterReference').value;
           
            if(this.isNullOrZeroOrUndefined(letterAdresValue)){
                this.validity_All = false;
                this.validateInput(
                    this.template.querySelector('lightning-input.input-letterAdres'),
                    this.validity_All,
                    this.labels.Please_enter_Address 
                );
            }else{
                this.validateInput(
                    this.template.querySelector('lightning-input.input-letterAdres'),
                    true,
                    ''
                );
            }
            
            if(this.isNullOrZeroOrUndefined(letterPoNumValue)){
                this.validity_All = false;
                this.validateInput(
                    this.template.querySelector('lightning-input.input-letterPoNum'),
                    this.validity_All,
                    this.labels.Please_enter_PO_Number 
                );
            }else{              
                this.validateInput(
                    this.template.querySelector('lightning-input.input-letterPoNum'),
                    true,
                    ''
                );
            }
                  
            if(this.isNullOrZeroOrUndefined(letterCityValue)){
                this.validity_All = false;
                this.validateInput(
                    this.template.querySelector('lightning-input.input-letterCity'),
                    this.validity_All,
                    this.labels.Please_enter_City 
                );
            }else{            
                this.validateInput(
                    this.template.querySelector('lightning-input.input-letterCity'),
                    true,
                    ''
                );
            }
            
            if(this.isNullOrZeroOrUndefined(letterCountryValue)){
                this.validity_All = false;
                this.validateInput(
                    this.template.querySelector('lightning-combobox.picklist-letterCountry'),
                    this.validity_All,
                    this.labels.Please_enter_Country  
                ); 
            }else{
                this.validateInput(
                    this.template.querySelector('lightning-combobox.picklist-letterCountry'),
                    true,
                    ''
                );
            }   
            if(this.validity_All){ 
                this.invoiceScreenFields = {
                    'invoiceType' : this.invoiceTypeVal,
                    'letterCoNameValue' : letterCoNameValue,
                    'letterAdresValue' :letterAdresValue,
                    'letterPoNumValue' : letterPoNumValue,
                    'letterCityValue' : letterCityValue,
                    'letterCountryValue' : letterCountryValue,
                    'letterReferenceValue' : letterReferenceValue,
                    'orderId' :this.orderId
                }
            }       
        }
       
        if(!this.validity_All){
            this.isLoading = false;
            return;
        } 
        //call apex only when all required fields are filled
        if(this.validity_All){            
            //call apex
            this.isLoading = true;
            this.saveInvoiceData(this.invoiceScreenFields);
        }       
    }

    /**
     * Call to apex for saving invoice information
     * @param {*} invoiceData 
     */
    saveInvoiceData(invoiceData){
       
        doSaveInvoiceData({invoiceData : JSON.stringify(invoiceData)})
        .then(data => {
            if(data){
                submitAppfromInvoiceSrc({
                    esignInfoId: this.orderId,
                    isUBO : this.isUBO,
                    saveLogsAsync : true
                }).then(result => {         
                    const resultParse = JSON.parse(result); 
                    if (result === '200'){
                        this.isLoading = false;
                        //if submit app sucess then redirect to esign page
                        this.redirectToSigningScreen(this.signUrl);
                    }           
                })
                .catch(error => {
                    this.isLoading = false;
                  
                    console.error(reduceErrors(error));
                    showPopUpNotification(
                        this,
                        reduceErrors(error), 
                        'error'
                    );
                });  
            }
                    
        })
        .catch(error => {
            this.isLoading = false;
            console.error(reduceErrors(error));
            showPopUpNotification(this, this.labels.Contact_Admin_Error, 'error');
        })
    }

    /**method to find if a value is valid or not */
    isNullOrZeroOrUndefined(value) {
        return value == null || value == undefined || value == 0 || value == '';
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
}