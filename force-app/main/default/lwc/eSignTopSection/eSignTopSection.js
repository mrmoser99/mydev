import { LightningElement,track,api } from 'lwc';
import { reduceErrors, dispatchPopUpNotification,constants,smartcommDocType, quoteStatuses } from 'c/ldsUtils';
import createEsignOrder from '@salesforce/apex/ESignInformationController.createEsignOrder';

export default class ESignTopSection extends LightningElement {
    labels = constants;
    smartcommDocType = smartcommDocType;
    quoteStatuses = quoteStatuses;
    @track docTypeValue ;//= this.smartcommDocType.Contract;
    @track tempDocTypeValue ;//= this.smartcommDocType.Contract;
    @track docNameValue;
    @track emailRows;
    @track emailRowRecords = [];
    @track index = 1;
    @api opportunityId;
    @api quoteId;
    @api documents;
    validity_All = true;
    @api primaryProduct;
    @track isLoading = false;
    @api currentQuoteStage;

    connectedCallback(){
        this.emailRows = 
        {
        'uid': this.index,
        'emailValue' : '',
        'isHideDelButton' : true
        };
        this.emailRowRecords.push(this.emailRows);
    }

    /**
     * Getting the list of contract document type for a particular esign record
     */
    get docTypeOptions() {
        let docTypeList = [];
        this.documents.forEach(index=>{
            let docType = '';
            if(index.type == this.smartcommDocType.Contract){
                docType = this.labels.Contract_Document_Type;
            }else if(index.type == this.smartcommDocType.AOD){
                docType = this.labels.Acceptance_Of_Delivery_Document_Type;
            }else if(index.type == this.smartcommDocType.Payment_Guarantor){      
                // For differenciating multiple PG doc
                docType = index.name;
            }
            if(docType != ''){               
               // docTypeList.push({ label: docType, value:  index.type});    
                docTypeList.push({ label: docType, value:  index.type+'#'+index.name});              
            }
            
        })
        return docTypeList;
    }

    /**
     * Disable buttons if quote status is Review Completed 
     */
    get disableButtons() {
        if (this.currentQuoteStage === this.quoteStatuses.ReviewCompleted) {
            return true;
        }
    }

    /**
     * 
     Add row method
     */
    handleAddRecords(event){
        let newData = JSON.parse(JSON.stringify(this.emailRowRecords));
        this.emailRows.uid = this.index + 1;  
        this.emailRows.emailValue = '';
        this.emailRows.isHideDelButton = false;
        this.index = this.index + 1;
        newData.push(this.emailRows);   
        this.emailRowRecords = newData;
        this.emailRows = {};  
    }

    /**
     * delete the selected row
     */
    handleDeleteRow(event){       
        var selectedRow = event.currentTarget;
        var key = selectedRow.dataset.id;
        if(this.emailRowRecords.length > 1){
            this.emailRowRecords.splice(key, 1);
            this.index--;
            this.emailRowRecords.forEach((element, index) => element.uid = index + 1);        
        }else if(this.emailRowRecords.length == 1){
            this.emailRowRecords = [];
            this.index = 0;          
        }  
    } 

    /**
     * Get doc type and name from selected option
     */
    handleChangeDocType(event){
        let selectedValue = event.target.value;
        const selArray =  selectedValue.split('#');
        this.docTypeValue = selArray[0];
        this.docNameValue = selArray[1];   
    }

    handleEmailChange(event) {
        var selectedRow = event.currentTarget;
        var key = selectedRow.dataset.id;
        this.emailRowRecords[key].emailValue = event.target.value;      
    }

    /**
     * Call apex and save the order records in sfdc
     */
    handleSendSignature(){ 
        this.isLoading = true;
        let newRecList = [];
        this.validity_All = true;
        for(let eachRec in this.emailRowRecords){
            const newRecObj = {
                'docType' : this.docTypeValue,
                'docName' : this.docNameValue,
                'email' : this.emailRowRecords[eachRec]['emailValue'],
                'opptyId' : this.opportunityId,
                'quoteId' : this.quoteId,
                'primaryProduct' : this.primaryProduct.prodName,
                'primaryProductDesc' : this.primaryProduct.prodDesc
            };
            newRecList.push(newRecObj);

            let dataId = this.emailRowRecords[eachRec]['uid'];
            let inputCmp = this.template.querySelector(`[data-id="${dataId-1}"]`); //get per row wise data
            let emailValue = inputCmp.value;
            
            let mailformat = /^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$/;

            let validity = !(!emailValue || emailValue.trim().length === 0 || !emailValue.match(mailformat))

            this.validateInput(
                inputCmp,
                validity,
                this.labels.Error_Enter_Valid_Email
            );

            //Check Document Type
            let doctypeInput = this.template.querySelector(`[data-id="dataType"]`);
            let docTypeValidity = !(this.docTypeValue == null);
            this.validateInput(
                doctypeInput,
                docTypeValidity,
                this.labels.Complete_this_field
            );

            if(!validity || !docTypeValidity){           
                this.validity_All = false;
                this.isLoading = false;
            }
          
        }
        
        if(this.hasDuplicateEmail(newRecList)){
            dispatchPopUpNotification(this, this.labels.Error_Duplicate_Emails_For_E_Sign, 'error');
            this.isLoading = false;
            return;
        }

        if(this.validity_All && !this.hasDuplicateEmail(newRecList)){  //call apex if there is no error at ui level and no duplicate email id provided
            const newRecListStr = JSON.stringify(newRecList);         
          
            //create Esign info Record
           this.createESign(newRecListStr);
        }
    }

    /**
     * Check if duplicate email in array
     */
    hasDuplicateEmail(array) {
        var hash = Object.create(null);
        return array.some(function (a) {
            return a.email && (hash[a.email] || !(hash[a.email] = true));
        });
    }

    eSignInfoResult(data){
      
        if(data){        
            const selectEvent = new CustomEvent('refresh', {
                detail: ''
            });
            this.dispatchEvent(selectEvent);
            dispatchPopUpNotification(this, this.labels.Success_Message_For_Email_Sending_For_E_Sign,'success');
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

    //create Esign info Record
    createESign(newRecListStr){
        createEsignOrder({esignInformation : newRecListStr})
        .then(data => {
            this.isLoading = false;
            this.eSignInfoResult(data);
        })
        .catch(error => {
            this.isLoading = false;
            console.error(reduceErrors(error));
            dispatchPopUpNotification(this, reduceErrors(error), 'error');
        });
    }
}