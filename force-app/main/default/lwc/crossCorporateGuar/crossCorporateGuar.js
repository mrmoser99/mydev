/* 

Change Log:

04/28/2022 - MRM - Added wait circle when searching

*/

import { LightningElement, api, wire, track} from 'lwc';
import quickSearch from "@salesforce/apex/CustomerUtils.quickSearch";
//import searchCustomer from "@salesforce/apex/CustomerUtils.searchCustomer";
import getCustomerId from "@salesforce/apex/CustomerUtils.getCustomerId";
import updateCustomerId from "@salesforce/apex/CustomerUtilsWithoutSharing.updateCustomerId";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import Email__c from '@salesforce/schema/Account.Email__c';
import Primary_Contact_Name__c from '@salesforce/schema/Account.Primary_Contact_Name__c';
import getCrossRelatedPartyForOpp from '@salesforce/apex/CreditApplicationHeaderController.getCrossRelatedPartyForOpp';

const columns = [

    //{ label: 'Select', fieldName: '', wrapText:false , initialWidth: 100 , sortable: true,  hideDefaultActions: 'true', },        
    { label: 'Customer Name', fieldName: 'Name', initialWidth: 225 ,wrapText:false ,sortable: true, hideDefaultActions: 'true'}, 
    { label: 'Address', fieldName: 'BillingStreet',initialWidth: 225 ,  sortable: true , hideDefaultActions: 'true'},
    { label: 'City', fieldName: 'BillingCity',  sortable: true, hideDefaultActions: 'true'},
    { label: 'State', fieldName: 'BillingState', sortable: true, hideDefaultActions: 'true'},
    { label: 'Zip', fieldName: 'BillingPostalCode', sortable: true , hideDefaultActions: 'true' },
    { label: 'Phone', fieldName: 'Phone',  sortable: true, hideDefaultActions: 'true'},
    
];

export default class CustomerQuickSearch extends LightningElement {

    statelist = [
        {value: '', label: ''},
        {value: 'AL', label: 'AL'},
        {value: 'AK', label: 'AK'},
        {value: 'AZ', label: 'AZ'},
        {value: 'AR', label: 'AR'},
        {value: 'CA', label: 'CA'},
        {value: 'CO', label: 'CO'},        
        {value: 'CT', label: 'CT'},
        {value: 'DE', label: 'DE'},
        {value: 'DC', label: 'DC'},
        {value: 'FL', label: 'FL'},
        {value: 'GA', label: 'GA'},
        {value: 'HI', label: 'HI'},
        {value: 'ID', label: 'ID'},
        {value: 'IL', label: 'IL'},
        {value: 'IN', label: 'IN'},        
        {value: 'IA', label: 'IA'},
        {value: 'KS', label: 'KS'},
        {value: 'KY', label: 'KY'},
        {value: 'LA', label: 'LA'},
        {value: 'ME', label: 'ME'},
        {value: 'MD', label: 'MD'},
        {value: 'MA', label: 'MA'},
        {value: 'MI', label: 'MI'},
        {value: 'MN', label: 'MN'},
        {value: 'MS', label: 'MS'},
        {value: 'MO', label: 'MO'},
        {value: 'MT', label: 'MT'},
        {value: 'NE', label: 'NE'},
        {value: 'NV', label: 'NV'},
        {value: 'NH', label: 'NH'},
        {value: 'NJ', label: 'NJ'},
        {value: 'NM', label: 'NM'},
        {value: 'NY', label: 'NY'},
        {value: 'NC', label: 'NC'},
        {value: 'ND', label: 'ND'},
        {value: 'OH', label: 'OH'},
        {value: 'OK', label: 'OK'},
        {value: 'OR', label: 'OR'},
        {value: 'PA', label: 'PA'},
        {value: 'PR', label: 'PR'},
        {value: 'RI', label: 'RI'},
        {value: 'SC', label: 'SC'},
        {value: 'SD', label: 'SD'},
        {value: 'TN', label: 'TN'},
        {value: 'TX', label: 'TX'},
        {value: 'UT', label: 'UT'},
        {value: 'VT', label: 'VT'},
        {value: 'VA', label: 'VA'},
        {value: 'WA', label: 'WA'},
        {value: 'WV', label: 'WV'},
        {value: 'WI', label: 'WI'},
        {value: 'WY', label: 'WY'}

    ];


    searchDataContract=[];

    init=true;
     
    @api recordId;
    columns=columns;
    showSlowSearch=false;
    loadMoreStatus;
    strSearchAccName='';
     
    
    city;
    @track state;
    @api isLoading=false;
    item;
     
    errorMsg;
    @track Customer={
        Name:'', 
        Primary_Contact_Name__c:'',
        Phone: '',  
        Email__c: '',
        BillingStreet: '',
        BillingCity: '',
        BillingCountry: '',
        BillingPostalCode: '',
        BillingCounty__c:'',
        Tax_ID__c: '',
        BillingState:''
              
    }; 
    isOpportunity;
    refreshExecute=0;
    hasRefreshed=false;
    @track showCustomer=false;
    showQuickSearch=true;
    showDataTable=false;
    objectName='Account';
    @track isModalOpen=false;
    errorStateMsg='';
    showCounty = false;
    

    /***********************************************************************************************************
    * getCustomerId
    ************************************************************************************************************/
    @wire(getCustomerId,{ recordId: '$recordId', refreshExecute : '$refreshExecute'}) 
        wiredgetCustomerId({data, error}) {

          //  this.customerInfoShowParent();
          
            if (this.recordId != null){

                if (!this.hasRefreshed) {
                    this.refreshExecute = Math.floor(Math.random() * 100000) + 2;
                    this.hasRefreshed = true;
                    return;
                }
                
                let str = this.recordId;

                if (str.startsWith('006'))
                    this.isOpportunity = true;
                else
                    this.isOpportunity = false;
                }
            else   
                return;


            if (data) {
                 
                this.customerId = data;
              //  this.showCustomer=true;
               // this.customerInfoShowParent();
            } else if (error) {  
                this.customerId = null; 
                this.showToast('Something went wrong', error.body.message, 'error');
                this.loading=false;
                return;
            }
            //this.isLoading = false;
    }


    connectedCallback(){
            //code to retrieve cross corp guarantor from apex and disply onload
            console.log('inside cross connected cb');
            getCrossRelatedPartyForOpp({oppId: this.recordId})
            .then(result => {
                if(result){
                    let resultParsed = JSON.parse(result);
                    this.showCustomer = true;
                    console.log('crossvalue' +JSON.stringify(result));
                    console.log('crossvalue' +resultParsed.First_Name__c);
                    this.Customer.Name = resultParsed.First_Name__c;
                    this.Customer.Phone = resultParsed.Phone__c;
                    this.Customer.Email__c = resultParsed.Email__c;
                    this.Customer.BillingStreet = resultParsed.Address_Line__c;
                    this.Customer.BillingCity = resultParsed.City__c;
                    this.Customer.BillingState = resultParsed.State__c;
                    this.Customer.BillingCounty__c = resultParsed.County__c;
                    this.Customer.BillingCountry = resultParsed.Country_Code__c;
                    this.Customer.Tax_ID__c = resultParsed.SSN_Encrypted__c;
                }
            })
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'sticky'
        });
        this.dispatchEvent(event);
    }

    closeModalpopup(event){
     
        this.isModalOpen = false;
        
        this.Customer = event.detail;
        this.updateCustomer();
        if(this.Customer != '' && this.Customer != null){
            console.log('inside closepopup guar' +JSON.stringify(this.Customer));
            this.showCustomer=true;
            this.customerInfoShowParent();
            //this.isLoading = false;
        }
        
    }

    handleAccountName(event) {
        this.strSearchAccName = event.detail.value;
        this.loadMoreStatus = null;
        this.errorMsg = null; 
        //this.handleSearch();
    }

    addCustomer(event) {
         
        this.isModalOpen=true;
         
    }
    
    handleCity(event) {
        this.city = event.detail.value;
        this.loadMoreStatus = null;
        this.errorMsg = null; 
    }

    /*handleOptionChange(event){
        console.log('wo');
    }*/

    handleState(event) {
        //Display error msg on change the value in  searchable drop down state field
        //start
        if(event.detail.value==undefined || event.detail.value=='' || event.detail.value == null) {
            this.errorStateMsg=event.detail;
         } else {
            this.errorStateMsg='';
         }
         //end
         this.state = event.detail.value;
     
        this.loadMoreStatus = null;
        this.errorMsg = null; 
    }
 

    handleClick(event) {
        this.isLoading = true;
        
         
        let inputFields = this.template.querySelectorAll('.validate');
        inputFields.forEach(inputField => {
            if(!inputField.checkValidity()) {
                inputField.reportValidity();
            }
        });

        this.showDataTable = false;
        
        
     
        this.searchData = [];
        this.errorMsg = null;
        this.loadMoreStatus = '';

        console.log('in search ' + this.isLoading);
        //Display error msg when we click on search button in  searchable drop down state field
        //start
        
        if(this.errorStateMsg!='') {
            this.template.querySelector('c-reusable-custom-dropdown-with-search-lwc').addErrorBorder();
            
        } 
        if(this.errorStateMsg=='') {
            if(this.state=='' || this.state==null || this.state==undefined) {
                this.errorStateMsg='Complete this field.';
                this.template.querySelector('c-reusable-custom-dropdown-with-search-lwc').addErrorBorder();
                
            }  else {
                this.template.querySelector('c-reusable-custom-dropdown-with-search-lwc').removeErrorBorder();
            }
        }
        //end

         
        if(!this.strSearchAccName) {
            this.errorMsg = 'Please enter account name to search.';
            this.searchData = [];
            this.isLoading = false;
            return;
        }

         

        if(!this.state) {
            this.errorMsg = 'Please enter state to search.';
            this.searchData = [];
            this.isLoading = false;
            return;
        }

        if(this.strSearchAccName.length < 3){
            this.errorMsg = 'Search name must contain 3 or more characters!';
            this.searchData = [];
            this.isLoading = false;
            return;

        }
        
        this.handleSearch();
         
    }   

    changeCustomer(event) {

      /*  this.customerId = null;
        //this.updateCustomer();
        this.showCustomer = false;
        this.customerInfoShowParent();
        this.strSearchAccName=null;
        this.city=null;
        this.state='';
        this.searchData=[];
        this.errorMsg = '';
        this.errorStateMsg='';
        this.showDataTable=false;
        this.searchDataContract = []; */
        console.log('inside changecust');
        this.isModalOpen = true;
        
        
    }

    updateCustomer(){

        updateCustomerId({isOpportunity : this.isOpportunity, recordId : this.recordId, customerId : this.customerId})
        .then(result => {
            console.log('result is ' + result);

            /* Disable refreshing the whole page
            const selectedEvent = new CustomEvent('progressvaluechange',{
                detail:'refresh'
            });
            this.dispatchEvent(selectedEvent);
            */
        })
        .catch(error => {
            this.searchData = undefined;
            window.console.log('error =====> '+JSON.stringify(error));
            if(error) {
                this.isLoading = false;
            }
        }) 

        
        
    }

    
    /*selectCustomer(event){

        if(!this.customerId) {
            this.errorMsg = 'Please select a customer to continue!';
            return;
        }

        this.updateCustomer();
        this.showCustomer=true;
        this.customerInfoShowParent();
    }*/

    getSelectedRecord(event) {

        const selectedRows = event.detail.selectedRows;
        // Display that fieldName of the selected rows
        for (let i = 0; i < selectedRows.length; i++){
          
            this.customerId = selectedRows[i].Id;
        }
    }

    handleCancel() {
        
        this.strSearchAccName = null;
        this.city = null;
        this.state = '';
        this.showDataTable = false;
        this.searchDataContract = [];
        this.showQuickSearch = true;
        this.errorMsg = null;
        this.template.querySelector('c-reusable-custom-dropdown-with-search-lwc').reset();
    }


    handleSearch() {

        quickSearch({strAccName : this.strSearchAccName, city : this.city, state: this.state})
        .then(result => {
          
            result = JSON.parse(result);
        
            let searchResultsContract = [];
             
            let customerList = result;
           
            if(customerList.length > 10 && this.city == null ){
                this.errorMsg = 'More than 10 accounts have been found.  Please add city to narrow the search!';
                this.searchData = [];
                this.isLoading = false;
                return;
            }
        
            customerList.forEach(record => {
                let preparedCustomer = {}; 
                preparedCustomer.Id = record.Id;
                preparedCustomer.Name = record.Name; 
                preparedCustomer.BillingStreet = record.BillingStreet;
                preparedCustomer.BillingCity = record.BillingCity;
                preparedCustomer.BillingState = record.BillingState;
                preparedCustomer.BillingPostalCode = record.BillingPostalCode;
                preparedCustomer.Phone = record.Phone;
                searchResultsContract.push(preparedCustomer);
            });

            this.searchDataContract = searchResultsContract;
            
                
            if (this.searchDataContract.length > 0){
                this.errorMsg = null;
                //this.showDataTable = true;
            }
            else
                this.errorMsg = 'No records to display!';

            this.isLoading = false;
            this.showDataTable = true;
            
        })
        .catch(error => {
            this.searchData = undefined;
            
            window.console.log('error =====> '+JSON.stringify(error));
            if(error) {
                //this.isLoading = false;
                this.loadMoreStatus = error.body.message;
                this.errorMsg = error.body.message;
            }
        }) 

        //this.isLoading = false;
         
    }   
    
    handleToggleSection(event) {
        this.activeSectionMessage =
            'Open section name:  ' + event.detail.openSections;
    }

    handleNotify(event) {
        this.isModalOpen=false;
    }
    
    customerInfoShowParent() {
        console.log('inside guar ' +JSON.stringify(this.Customer));
        const selectedEvent = new CustomEvent('customerinfoshow',{
            detail: this.Customer
        });
        this.dispatchEvent(selectedEvent);
    }

    
}