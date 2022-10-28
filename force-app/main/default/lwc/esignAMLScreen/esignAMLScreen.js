import { LightningElement, track } from 'lwc';
import { reduceErrors, showPopUpNotification, getUrlParamValue,constants,esignStatuses,smartcommDocType } from 'c/ldsUtils';
import { NavigationMixin } from 'lightning/navigation';
import createAndDeleteContact from '@salesforce/apex/ESignInformationController.createAndDeleteContact';
import sendCodeToAzure from '@salesforce/apex/RESTCalloutHelper.sendCode';
import createOrder from '@salesforce/apex/RESTCalloutHelper.createOrder';
import getESignInformation from '@salesforce/apex/ESignInformationController.getEsignInfoString';
import getMultipleSignerInfo from '@salesforce/apex/ESignInformationController.getMultipleSignerInfo';
import getExistingContacts from '@salesforce/apex/ESignInformationController.getExistingContactsString';


export default class EsignAMLScreen extends NavigationMixin(LightningElement) {
    labels = constants;
    esignStatuses = esignStatuses;
    smartcommDocType = smartcommDocType;
    /**Variables declaration Start*/
    userShowAddDelButton = true;  //toggle add & delete button in user esign table
    @track esignData = [];
    @track edata;
    radioValue = '';
    contactResult;
    @track index = 1;
    contactvalue;
    codeKey = 'code';
    code;
    orderId;
    pageForSigning;
    signUrl;
    isLoading = false;
    showAmlScreen = false;
    showTable = false;
    validity_All = true;
    showFirstRow = true;
    @track contactsBeforeDelete = [];
    deletedContactIds = [];
    documentType = '';
    spinnerText = '';
    fromInvPage = false;
    contractStatus = ''; //Status of Contract type Doc if already signed by any Signer 
    @track isUBO = false;

    /**Variables declaration End*/
    connectedCallback(){
        document.title = "Esign";
        this.getParams();
    }

    /**
     * Set initial data table to display it when Azure successfuly updates Signer Info
     */
    setInitialTableDate(showDelButton) {
        this.edata = {
            'uid': this.index,
            'NameValue' : '',
            'SSNValue' : '',
            'MaskSSNValue' : '',
            'contactId' : '',
            'isHideDelButton' : showDelButton
            };
        this.esignData.push(this.edata);
        return this.esignData;
    }

    /**
     * Get params from ULR by keys
     */
    getParams() {
        //if aml page opened from previous button of invoice page
        this.fromInvPage = getUrlParamValue(window.location.href, 'fromInvPage');     
        if(this.fromInvPage){
            this.orderId = getUrlParamValue(window.location.href, 'orderId');
            this.signUrl = getUrlParamValue(window.location.href, 'signUrl');
            this.getExistingContacts();
        }else{
            this.fromInvPage = false;
            this.code = encodeURIComponent(getUrlParamValue(window.location.href, this.codeKey));
            this.orderId = getUrlParamValue(window.location.href, 'nonce').split('-')[0].replace('SFDC', '');  
            this.getExistingContacts();
            this.checkOrderInfo();
        }       
        
    }

    /**method to find if a value is valid or not */
    isNullOrZeroOrUndefined(value) {
        return value == null || value == undefined || value == 0 || value == '';
    }
    /**
     *Show existing contacts of this orderid in the table.
     */
    getExistingContacts(){        
        this.isLoading = true;
        getExistingContacts({
            orderId : this.orderId
        }).then(result => {         
            let data = JSON.parse(result);       
            if(!this.isNullOrZeroOrUndefined(data)){
                this.showFirstRow = false;
                this.radioValue = data[0]['ultimateBenOwner'] ? 'yes' : 'no';       
                this.showTable = this.radioValue == 'yes' ? true : false;
                this.isUBO = this.showTable;
                for (const eachRec in data) {
                    const newRecObj = {
                        'uid' : this.index,
                        'NameValue' : data[eachRec]['contactName'],
                        'SSNValue' : data[eachRec]['ssn'], 
                        'contactId' : data[eachRec]['contactId'],
                        'isHideDelButton' : this.index == 1 ? true : false,
                        'MaskSSNValue' : data[eachRec]['ssn'] != null ? (data[eachRec]['ssn']).slice(0,-4)+'XXXX' : ''

                    }; 
                    
                    this.esignData.push(newRecObj);
                    this.contactsBeforeDelete.push(newRecObj);
                    this.index++;
                }                        
            }       
            if(this.fromInvPage){
                this.showAmlScreen = true;
                this.isLoading = false;
            }              
        })
        .catch(error => {
            console.error(reduceErrors(error));
            this.isLoading = false;
        })
    }

    /**
     * Check order status. If it is "New" aml screen table will be displayed.
     * If status is "Active" user will be redirected to sign document page
     * if contract doc type, open AML screen. if doc type = PG/AOD, skip AML screen,
            do callout to azure for signer info & iframe urldirectly go to e-sign page.
     */
    checkOrderInfo() {
        this.isLoading = true;
        getESignInformation({eSignInfoId: this.orderId})
        .then(result => {         
            let data = JSON.parse(result);
            let eSingStatus = data.Status__c;
            this.documentType = data.Document_Type__c;
           
            if(data.Document_Type__c == this.smartcommDocType.Contract && eSingStatus === this.esignStatuses.New){ //for contract
               // get Status of Contract document type and check if any of the signer already complete signing process or not
                this.getMultipleSignerDtl(data);
                
                if(this.showFirstRow)
                    this.setInitialTableDate(true);
                this.sendCode();
            }else if (data.Document_Type__c == this.smartcommDocType.Contract && eSingStatus === this.esignStatuses.Active) {
                 //for contract
                if (data.iFrame_URL__c != null) {
                    this.redirectToSigningScreen(data.iFrame_URL__c);
                } else {
                    showPopUpNotification(this, this.labels.Contact_Admin_Error, 'error');
                } 
            }else if (data.Document_Type__c === this.smartcommDocType.AOD || data.Document_Type__c === this.smartcommDocType.Payment_Guarantor) { 
                //for aod/aml, directly open the e-signing page, skip aml screen
                this.isLoading = true;    
                this.spinnerText = this.labels.Esign_Loading_AML_text;                  
                if (data.iFrame_URL__c != null) {
                    this.redirectToSigningScreen(data.iFrame_URL__c);
                } else {
                    this.sendCode(); //send code callout 
                }   
            }
        })
        .catch(error => {
            console.error(reduceErrors(error));
            showPopUpNotification(this, this.labels.Contact_Admin_Error, 'error');
            this.isLoading = false;
        })
    }

    /**
     * Call Apex method and perform Send Code callout to Azure.
     * Code should be used by Azure to get Signer information.
     * Order Id also is sent to identify which recod Azure has to update
     */
    sendCode() {
        let params = JSON.stringify({
            code: this.code,
            additional_info: this.orderId
        });
        sendCodeToAzure({paramsString: params})
        .then(result => {
            let response = JSON.parse(result);
            if (response['Error message'] != null) {
                console.error('error=='+response['Error message']);
                this.isLoading = false;
                showPopUpNotification(this, response['Error message'],'error');
            } else {  
                //check if Document Type AOD Or PG then skip AML Screen
                //Also if Document Type is Contract and in case of multiple signer if any signer complete signing process then skip AML screen for other signers         
                if(this.documentType === this.smartcommDocType.AOD || this.documentType === this.smartcommDocType.Payment_Guarantor || this.contractStatus === 'Complete'){
                    //callout to azure for creating the order in NETS
                    this.createOrder(); 
                }else{
                    this.showAmlScreen = true;
                    this.isLoading = false;
                }             
            }
        })
        .catch(error => {
            console.error(reduceErrors(error));
        })
    }

    /**
     * Get options for lightning-radio-group component
     */
    get options(){
        return[
            { label: this.labels.Yes, value:'yes'},
            { label: this.labels.No, value:'no'},
        ];
    }

    /**
     * To get the radio button value on change of the selection
     */
    handleRadioButtonChange(event){
        this.radioValue = event.target.value;
        this.showTable = this.radioValue == 'yes' ? true : false;
        this.isUBO = this.showTable;
    }

    /**
     * Add new row in the table
     */
    handleAddRecords(event){
     
        let newData = JSON.parse(JSON.stringify(this.esignData));
        this.index = this.index + 1;
        this.esignData = this.setInitialTableDate(false);
        this.edata = {};
      
    }

    /**
     * Delete the selected row
     */
    handleDeleteRow(event){ 
        
        var selectedRow = event.currentTarget;      
        var key = selectedRow.dataset.id; //get row id
        if (this.esignData.length > 1) {
            this.esignData.splice(key, 1);
            this.index--;
            this.esignData.forEach((element, index) => element.uid = index + 1);        
        } else if (this.esignData.length == 1) {
            this.esignData = [];
            this.index = 0;          
        }
        
        this.prepareToDeleteContacts(this.contactsBeforeDelete,this.esignData);
       
    } 

    /**
     * delete contacts from salesforce
     */
    prepareToDeleteContacts(contactsBeforeDelete,contactsAfterDelete){
        let deletedContact = contactsBeforeDelete.filter(e => !contactsAfterDelete.find(a => e.contactId === a.contactId));  
        for(let eachIndex in deletedContact){
            this.deletedContactIds.push(deletedContact[eachIndex]['contactId']);
        }   
    }
    /**
     * Set new Name value in the esignData object by row id
     */
    handleNameChange(event) {
        var selectedRow = event.currentTarget;
        var key = selectedRow.dataset.id;
        this.esignData[key].NameValue = event.target.value;       
    }

    /**
     * Set new SSN value in the esignData object by row id
     */
    handleSSNChange(event) {
        var selectedRow = event.currentTarget;
        var key = selectedRow.dataset.id; 
        this.esignData[key].SSNValue = event.target.value;     
    }

    /**
     * Call apex and save the order records in sfdc. create contacts
     * esign user Data
     */
    handleSendAML() {
       
        let newRecList = [];       
        this.validity_All = true;
        this.isLoading = true;   
        let validity = true;
        //if user didnt select the radio option
        validity = !(this.isNullOrZeroOrUndefined(this.radioValue));
        if(!validity && !this.showTable){
            this.validity_All = false;
            showPopUpNotification(this, 'Please select an option','error');
            this.isLoading = false;
            return;
        }
        for (let eachRec in this.esignData) {
            let nameValue = this.esignData[eachRec]['NameValue'];  
            let ssnValue = this.esignData[eachRec]['SSNValue'];        
            validity = !(!nameValue || !ssnValue);
            const ssnValidity = this.validateSSN(ssnValue);

            if(!ssnValidity && this.showTable){
                this.validity_All = false;
                this.isLoading = false;
                showPopUpNotification(this, this.labels.Valid_SSN_error+eachRec,'error');
                return;
            }
                    
            if(!validity && this.showTable){
                this.validity_All = false;
                this.isLoading = false;
                showPopUpNotification(this, this.labels.Error_Please_Fill_All_Details,'error');
                return;
            }
            const newRecObj = {
                'contactName' : this.esignData[eachRec]['NameValue'],
                'ssn' : this.esignData[eachRec]['SSNValue'],
                'orderId' : this.orderId,
                'contactId' : this.esignData[eachRec]['contactId'],
                'ultimateBenOwner' : this.radioValue == 'yes' ? true : false
            };
            newRecList.push(newRecObj);
        }
        
        //call apex if there is no error at ui level        
        if(this.validity_All){
            const newRecListStr = JSON.stringify(newRecList);
            createAndDeleteContact({
                ContactJSON : newRecListStr,
                deletedContactIds : this.deletedContactIds,
                orderId : this.orderId,
            })
            .then(data => {
                this.amlInfoResult(data);     
                this.isLoading = true;     
                //callout to azure for creating the order in NETS
                if(!this.fromInvPage){
                    this.createOrder();
                }else{
                    this.redirectToInvoicePage(this.signUrl); 
                }           
                
            })
            .catch(error => {
                console.error(reduceErrors(error));
                //show error pop-up notification
                showPopUpNotification(this, reduceErrors(error),'error');
            })
        }            
    }

    //pass the order to azure to create in NETS
    createOrder(){
        this.isLoading = true;
        createOrder({orderId : this.orderId }) 
        .then(data => {    
            const orderData = JSON.parse(data);
            if(orderData['Error message']){
                showPopUpNotification(this, orderData['Error message'],'error'); //show error pop-up notification    
                this.isLoading = false;       
            }else{
                if(orderData['iframeURL']){
                    //check if Document Type AOD Or PG then skip Invoice Screen
                    //Also if Document Type is Contract and in case of multiple signer if any signer complete signing process then skip Invoice screen for other signers   
                    if(this.documentType === this.smartcommDocType.AOD || this.documentType === this.smartcommDocType.Payment_Guarantor  || this.contractStatus === 'Complete'){
                        this.redirectToSigningScreen(orderData['iframeURL']);  
                    }else{
                        this.redirectToInvoicePage(orderData['iframeURL']);
                    }
                    
                }   
                
                this.isLoading = false;  
            }
        })
        .catch(error => {
            console.error(reduceErrors(error));
            this.isLoading = false;  
            //show error pop-up notification
            showPopUpNotification(this, reduceErrors(error),'error');          
        })

    }

    //validate the ssn number is entered in proper format
    validateSSN (elementValue){
        var  ssnPattern = /^[0-9]{8}\-[0-9]{4}$/;
        return ssnPattern.test(elementValue);
    }

    /**
     * Redirect user to sign document when order status is "Active"
     */
    redirectToSigningScreen(signUrl){
        
        this.pageForSigning = {
            type: 'standard__webPage',
            attributes: {
                url: this.labels.Public_Community_URL + 'esigning-page?signUrl=' + encodeURIComponent(signUrl)        
            }
        }

        this[NavigationMixin.Navigate](this.pageForSigning);
    }

     /**
     * Redirect user to invoice Page
     */
      redirectToInvoicePage(signUrl){
        
        let invoicePage = {
            type: 'standard__webPage',
            attributes: {
                url: this.labels.Public_Community_URL + 'esign-invoice-page?signUrl=' + encodeURIComponent(signUrl)+'&orderId='+this.orderId+'&isUBO='+this.isUBO
            }
        }

        this[NavigationMixin.Navigate](invoicePage);
    }

    //get new deal button class name
    get mainDivClass(){
        //if changeStle is true, getter will return class1 else class2
          return !this.isLoading ? 'aml-form slds-p-around_large white-bg slds-is-relative': 'aml-form slds-p-around_large slds-is-relative';
      }

    /**
     * Display notification with result after Apex call
     */
    amlInfoResult(data){
        if (data) {   
            //show successful pop-up notification     
            showPopUpNotification(this, this.labels.Success_Message_Data_Updated_Successfully,'success');
        } else {
            //show error pop-up notification
            showPopUpNotification(this, this.labels.Contact_Admin_Error,'error');
        }
    }

    //check if there is multiple signer of Contract then get Contract Status and skip AML Screen
    // for other Signers, if any of the signer already complete signing process 
    getMultipleSignerDtl(data){           
        getMultipleSignerInfo({quoteId: data.Quote__c,
                                documentName : data.Document_Name__c
                            }) 
        .then(signerResult => {         
            this.contractStatus = signerResult;
        })
        .catch(error => {
            console.error(reduceErrors(error));
            showPopUpNotification(this, this.labels.Contact_Admin_Error, 'error');
            this.isLoading = false;
        })
    }   
}