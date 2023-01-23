import { LightningElement ,track, api, wire } from 'lwc';
import getAddValidation from '@salesforce/apex/GetAddressValidation.getAddValidation';
import getAllstates from '@salesforce/apex/GetAddressValidation.getAllstates';
import insertAccount from '@salesforce/apex/GetAddressValidation.insertAccount';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import stateLabel from '@salesforce/label/c.stateList'; 
import accName from '@salesforce/schema/Account.Name';
import primaryContact from '@salesforce/schema/Account.Primary_Contact_Name__c';
import phone from '@salesforce/schema/Account.Phone';
import email from '@salesforce/schema/Account.Email__c';
import billingstreet from '@salesforce/schema/Account.billingstreet';
import billingcountry from '@salesforce/schema/Account.BillingCounty__c';
import billingcity from '@salesforce/schema/Account.billingcity';
import billingPostalCode from '@salesforce/schema/Account.billingPostalCode';
import billingtaxId from '@salesforce/schema/Account.Tax_ID__c';
import getRelatedParty_onload from '@salesforce/apex/CreditApplicationHeaderController.getRelatedParty_onload';

export default class AddressStandardization extends LightningElement {
    
    @track Customer={
        Name:accName, 
        Primary_Contact_Name__c:'',
        Phone: '',  
        Email__c: '',
        BillingStreet: billingstreet,
        BillingCity: billingcity,
        BillingCountry: 'US',
        BillingPostalCode: billingPostalCode,
        BillingCounty__c:'',
        Tax_ID__c: '',
        BillingState:'',
        addressline2:''
              
    }; 

    @api cusdata={
        Name:accName, 
        Primary_Contact_Name__c:'',
        Phone: '',  
        Email__c: '',
        BillingStreet: billingstreet,
        BillingCity: billingcity,
        BillingCountry: 'US',
        BillingPostalCode: billingPostalCode,
        BillingCounty__c:'',
        Tax_ID__c: '',
        BillingState:'',
        addressline2:''
              
    }; 

    @api showmodel;
    @api isModalOpen;
    @api recordid;
    @track phoneFilled=false;
    @track stateOptions =[];
    @track stateList=  stateLabel.split(','); 
    @track data = [];
    @track showCustomerForm = true;
    @track isValidated = false;
    @track showNextButton=false;
    @track showselectedoutput=false;
    @track loader = false;
    @track billingAddressLine2 = ''; 
    @track respAdd1;
    @track respCounty;
    @track respCity;
    @track respState;
    @track respCountry;
    @track respPostalCode;
    @track isSuccess = false;


    @track finalAdd1;
    @track finalCounty
    @track finalCity;
    @track finalState;
    @track finalCountry;
    @track finalPostalCode;
    @track selected;
    

    @track stateVisit = false;
    @track errorMsg='';


 account ={};
 connectedCallback(){
    console.log('first line connected callback' +this.recordid);
    if(this.cusdata){
        console.log('in connected callback cust' +JSON.stringify(this.cusdata));
        this.Customer = {...this.cusdata};
    }

   console.log('tst' +JSON.stringify(this.Customer));
 getAllstates().then(result =>{
if(result){
this.data = result;
let options = [];
console.log('this data' +this.data);
for(var key in this.data){
    console.log('this key' +key);
    options.push({'label':this.data[key], 'value':this.data[key]});
  }
  this.stateOptions = options;

}

 }).catch(error =>{
     this.error =error;
    // this.loader = false;
 })
}
onCustNamechange (event){
     this.Customer.Name = event.target.value;
 }

 onPrimaryConchange (event) {
     this.Customer.Primary_Contact_Name__c = event.target.value;
 }

 onPhonechange (event){
     this.Customer.Phone = event.target.value;
     if(this.Customer.Phone!='' || this.Customer.Phone!=undefined || this.Customer.Phone!=null) {
        this.phoneFilled=true;
     } else {
        this.phoneFilled=false;
     }
     if(!this.Customer.Phone.includes('-') &&  this.Customer.Phone != null && this.Customer.Phone.substring(3) !=null && this.Customer.Phone.substring(6) !=null){
       
        if(this.Customer.Phone.length>6){
           this.Customer.Phone  = +this.Customer.Phone.substring(0, 3)+'-'+this.Customer.Phone.substring(3, 6)+'-'+this.Customer.Phone.substring(6);
        }

    }
 }

 onEmailchange (event){
     this.Customer.Email__c = event.target.value;
 }

 onAdd1change(event){
     this.Customer.BillingStreet = event.target.value;
 }

 onAdd2change (event){
    if(event.target.value) {
        this.billingAddressLine2 = event.target.value;
        this.Customer.addressline2 = this.billingAddressLine2;
    }
 }

 onCitychange (event){
     this.Customer.BillingCity = event.target.value;
 }

 onStatechange (event){
     if(event.detail.value==undefined || event.detail.value=='' || event.detail.value == null) {
        this.errorMsg=event.detail;
     } else {
        this.errorMsg='';
     }
     //stateOptions
     this.Customer.BillingState = event.detail.value;
    
 }

 onPostalCodechange (event){
    this.Customer.BillingPostalCode = event.target.value;
 }

 onCountrychange (event){
    console.log('tst1' +JSON.stringify(event.target.value));
     this.Customer.BillingCountry = event.target.value;
 }

 onTaxIDchange (event){
     this.Customer.Tax_ID__c = event.target.value;

if(!this.Customer.Tax_ID__c.includes('-') &&  this.Customer.Tax_ID__c != null && this.Customer.Tax_ID__c.substring(2) !=null){
if(this.Customer.Tax_ID__c.length>3){
    this.Customer.Tax_ID__c  = this.Customer.Tax_ID__c.substring(0, 2)+'-'+this.Customer.Tax_ID__c.substring(2);
}
    



}
    }

statuslist = [
        {value: 'US', label: 'US', selected :true}
    ]; 
    
    isInputValid() {
        let isValid = true;
        console.log('this.errorMsg:::'+this.errorMsg);
        console.log('cust ' +JSON.stringify(this.Customer));
        if(this.Customer.BillingState=='') {
            this.errorMsg='Complete this field.';
            this.template.querySelector('c-reusable-custom-dropdown-with-search-lwc').addErrorBorder();
            isValid = false;
        } else if(this.errorMsg!='') {
            isValid = false;
            this.template.querySelector('c-reusable-custom-dropdown-with-search-lwc').addErrorBorder();
        } else {
            this.template.querySelector('c-reusable-custom-dropdown-with-search-lwc').removeErrorBorder();
        }
        let inputFields = this.template.querySelectorAll('.validate');
        console.log(inputFields.length);
        inputFields.forEach(inputField => {
            console.log('inputfield' +inputField.checkValidity());
            if(!inputField.checkValidity()) {
                inputField.reportValidity();
                isValid = false;
            }
            console.log('above value' +inputField.value ) ;
            console.log('above name ' +inputField.name );
            console.log('above cust' +JSON.stringify(this.Customer));
            this.Customer[inputField.name] = inputField.value;
            console.log(' below value' +inputField.value ) ;
            console.log(' below name' +inputField.name );
            console.log(' below cust' +JSON.stringify(this.Customer));
        });
        console.log('isvalid' +isValid);
        return isValid;
        
    }
 
    handleValidateAddress (){   
    this.loader = true;
   
        if(this.isInputValid()){
        getAddValidation( {act:this.Customer, billingAddressLine2:this.billingAddressLine2})
        .then(result=>{
            console.log(JSON.stringify(result));
            this.isValidated = true;
            this.showCustomerForm = false;
            this.respAdd1 = result.addressLine1;
            this.respCounty = result.county;
            this.respCity = result.city;
            this.respState = result.state;
            this.respCountry = result.country;
            this.respPostalCode = result.postalCode;
          this.isSuccess = result.isSuccess;
          if(this.Customer.Phone != ''){
          this.Customer.Phone = this.Customer.Phone;
        }
            console.log(this.Customer);
this.selected  = 'Suggested Address' ;
this.finalAdd1 = this.respAdd1;
this.finalCounty = this.respCounty;
this.finalCity = this.respCity;
this.finalState = this.respState;
this.finalCountry =  this.respCountry;
this.finalPostalCode = this.respPostalCode;


            this.loader = false;
        }).catch(error =>{
            this.error =error;
            this.loader = false;
            console.log('error ' +JSON.stringify(this.error));
        })
    }else{
    this.loader=false;
}

    }
    handleRadioClick(event){
this.showNextButton = true;
     console.log( event.target.value);
     console.log( event.target.label);
     this.selected = event.target.label;
    console.log('this.billingAddressLine2 = ' +this.billingAddressLine2);
   
     if(this.selected == 'User Entered Address'){
        this.finalAdd1 = this.Customer.BillingStreet +' '+ this.billingAddressLine2;
       //this.finalAdd1 = this.Customer.BillingStreet;
        this.finalCounty = this.Customer.county;
        this.finalCity = this.Customer.BillingCity;
        this.finalState = this.Customer.BillingState;
        this.finalCountry =  this.Customer.BillingCountry;
        this.finalPostalCode = this.Customer.BillingPostalCode;


     }else {
        this.finalAdd1 = this.respAdd1;
        this.finalCounty = this.respCounty;
        this.finalCity = this.respCity;
        this.finalState = this.respState;
        this.finalCountry =  this.respCountry;
        this.finalPostalCode = this.respPostalCode;

     }
    }
   
    handleCustomerCreate(){
        this.loader = true;
            if((this.isSuccess==false || this.isSuccess==undefined ) && this.selected=='Suggested Address') {
              console.log('test inside cust create');
                const evt = new ShowToastEvent({
                    title: 'Invalid Address',
                    message: 'Please select the valid address',
                    variant: 'info',
                    duration:10000,
                });
                this.dispatchEvent(evt);
                this.loader = false;
            } else {
                console.log('test inside cust create else');
                this.Customer.BillingStreet = this.finalAdd1;
                this.Customer.BillingCounty__c = this.finalCounty;
                this.Customer.BillingCity = this.finalCity;
                this.Customer.BillingState = this.finalState;
                this.Customer.BillingCountry = this.finalCountry;
                this.Customer.BillingPostalCode = this.finalPostalCode;
               
                //this.Customer.Phone = '(+1)'+this.Customer.Phone;
                console.log('add2 is ' +this.billingAddressLine2);
                console.log('customer = ' +JSON.stringify(this.Customer));
                    this.loader = false;
                    const eventCancel = new CustomEvent('cancelevent',{detail:  this.Customer});
                    this.dispatchEvent(eventCancel);
                 
            }
        }

    handleBack(){
        this.isValidated = false;
        this.showCustomerForm = true;
        console.log('this.Customer.BillingState::'+this.Customer.BillingState);
        //this.showselectedoutput = true;
    }

    handlecancel(event){
      
        //calling apex method
        getRelatedParty_onload({
            oppId : this.recordid,
            conType: "CrossCorporate"
        })
        .then(result=>{

            console.log('corp add handle cancel ' +JSON.stringify(result));
            this.Customer.Name = result.First_Name__c;
            const eventCancel = new CustomEvent('cancelevent',{detail:this.Customer});
            this.dispatchEvent(eventCancel);
            console.log('fired');
        })
        .catch(error => {
            const eventCancel = new CustomEvent('nodataevent',{detail:this.Customer});
            this.dispatchEvent(eventCancel);
            console.log('no data fired');
        })
      
    }

    handelCloseDropDown() {
        this.template.querySelector('c-reusable-custom-dropdown-with-search-lwc').toggleOpenDropDown(false);
    }

   


}