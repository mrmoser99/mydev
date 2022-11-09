import createNewOppForCreditCheck from '@salesforce/apex/CreditApplicationHeaderController.createNewOppForCreditCheck';
import getRelatedPartyForOpp from '@salesforce/apex/CreditApplicationHeaderController.getRelatedPartyForOpp';
import saveRelatedPartyForOpp from '@salesforce/apex/CreditApplicationHeaderController.saveRelatedPartyForOpp';
import saveRelatedPartyForOpp1 from '@salesforce/apex/CreditApplicationHeaderController.saveRelatedPartyForOpp1';
import saveComments from '@salesforce/apex/CreditApplicationHeaderController.saveComments';
import createPickListValues from '@salesforce/apex/CreditApplicationHeaderController.picklistValues';
import getContactField from '@salesforce/apex/CreditApplicationHeaderController.getContactField';
import getOpportunityField from '@salesforce/apex/CreditApplicationHeaderController.getOpportunityData';
import getQuoteLineField from '@salesforce/apex/CreditApplicationHeaderController.getQuoteLineData';
import getQuoteLineForAccessoryField from '@salesforce/apex/CreditApplicationHeaderController.getQuoteLineAccessoryData';
import getSalesReps from "@salesforce/apex/PricingUtils.getSalesReps";
import getSalesRepsFromReturnedOSID from "@salesforce/apex/CreateQuoteOpportunity.getSalesRepsFromReturnedOSID";
import getUserSite from "@salesforce/apex/PricingUtils.getUserSite";
import submitCreditApp from '@salesforce/apex/CreditAppUtils.submitCreditApp';
import submitPreQualCreditApp from '@salesforce/apex/CreditAppUtils.submitPreQualCreditApp';
import UpdateBenefitOwnerData from '@salesforce/apex/CreditApplicationHeaderController.UpdateBenefitOwnerData';
import UpdateQuoteData from '@salesforce/apex/CreditApplicationHeaderController.UpdateQuoteData';
import {api, track, LightningElement, wire} from 'lwc';
import {CurrentPageReference} from 'lightning/navigation';
import {NavigationMixin} from 'lightning/navigation';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';

// Custom Labels
import CREDITAPP_CUSTOMERAPPROVAL_MESSAGE from '@salesforce/label/c.CREDITAPP_CUSTOMERAPPROVAL_MESSAGE';
import CREDITAPP_CUSTOMERAPPROVAL_TITLE from '@salesforce/label/c.CREDITAPP_CUSTOMERAPPROVAL_TITLE';
import CREDITAPP_CUSTOMERINFO_MESSAGE from '@salesforce/label/c.CREDITAPP_CUSTOMERINFO_MESSAGE';
import CREDITAPP_CUSTOMERINFO_TITLE from '@salesforce/label/c.CREDITAPP_CUSTOMERINFO_TITLE';
import CREDITAPP_INTERVAL from '@salesforce/label/c.CREDITAPP_INTERVAL';
import CREDITAPP_SAVED_MESSAGE from '@salesforce/label/c.CREDITAPP_SAVED_MESSAGE';
import CREDITAPP_SAVED_TITLE from '@salesforce/label/c.CREDITAPP_SAVED_TITLE';
import CREDITAPP_SAVING_MESSAGE from '@salesforce/label/c.CREDITAPP_SAVING_MESSAGE';
import CREDITAPP_SAVING_TITLE from '@salesforce/label/c.CREDITAPP_SAVING_TITLE';
import CREDITAPP_SUBMITTED_MESSAGE from '@salesforce/label/c.CREDITAPP_SUBMITTED_MESSAGE';
import CREDITAPP_SUBMITTED_TITLE from '@salesforce/label/c.CREDITAPP_SUBMITTED_TITLE';
import CREDITAPP_SUBMITTEDERROR_400_500 from '@salesforce/label/c.CREDITAPP_SUBMITTEDERROR_400_500';
import CREDITAPP_SUBMITTEDERROR_404 from '@salesforce/label/c.CREDITAPP_SUBMITTEDERROR_404';
import CREDITAPP_SUBMITTEDERROR_GENERAL from '@salesforce/label/c.CREDITAPP_SUBMITTEDERROR_GENERAL';
import CREDITAPP_SUBMITTEDERROR_MESSAGE from '@salesforce/label/c.CREDITAPP_SUBMITTEDERROR_MESSAGE';
import CREDITAPP_SUBMITTEDERROR_TITLE from '@salesforce/label/c.CREDITAPP_SUBMITTEDERROR_TITLE';
import CREDITAPP_TIMEOUT from '@salesforce/label/c.CREDITAPP_TIMEOUT';
import CREDITAPP_UBO_COUNTRY from '@salesforce/label/c.CREDITAPP_UBO_COUNTRY';
import CREDITAPP_UBO_FIRSTNAME from '@salesforce/label/c.CREDITAPP_UBO_FIRSTNAME';
import CREDITAPP_UBO_LASTNAME from '@salesforce/label/c.CREDITAPP_UBO_LASTNAME';
import CREDITAPP_UBO_REQUIRED from '@salesforce/label/c.CREDITAPP_UBO_REQUIRED';
import CREDITAPP_UBO_TITLE from '@salesforce/label/c.CREDITAPP_UBO_TITLE';
import ENROLL_ENABLED from '@salesforce/label/c.ENROLL_ENABLED';

import UPLOAD_DOC from '@salesforce/label/c.UPLOAD_DOC';
import UPLOAD_DOC_DESC from '@salesforce/label/c.UPLOAD_DOC_DESC';
import UPLOADED_DOC from '@salesforce/label/c.UPLOADED_DOC';
import UPLOADED_DOCS_DESC from '@salesforce/label/c.UPLOADED_DOCS_DESC';
import { refreshApex } from '@salesforce/apex';
import getRelatedFilesByRecordId from '@salesforce/apex/EnrollController.getRelatedFilesByRecordId';
import deleteContentDocument from '@salesforce/apex/EnrollController.deleteContentDocument';

export default class CreditAppAdditionalInfo extends NavigationMixin(LightningElement){
    label = {
        CREDITAPP_CUSTOMERAPPROVAL_MESSAGE,
        CREDITAPP_CUSTOMERAPPROVAL_TITLE,
        CREDITAPP_CUSTOMERINFO_MESSAGE,
        CREDITAPP_CUSTOMERINFO_TITLE,
        CREDITAPP_INTERVAL,
        CREDITAPP_SAVED_MESSAGE,
        CREDITAPP_SAVED_TITLE,
        CREDITAPP_SAVING_MESSAGE,
        CREDITAPP_SAVING_TITLE,
        CREDITAPP_SUBMITTED_MESSAGE,
        CREDITAPP_SUBMITTED_TITLE,
        CREDITAPP_SUBMITTEDERROR_400_500,
        CREDITAPP_SUBMITTEDERROR_404,
        CREDITAPP_SUBMITTEDERROR_GENERAL,
        CREDITAPP_SUBMITTEDERROR_MESSAGE,
        CREDITAPP_SUBMITTEDERROR_TITLE,
        CREDITAPP_TIMEOUT,
        CREDITAPP_UBO_COUNTRY,
        CREDITAPP_UBO_FIRSTNAME,
        CREDITAPP_UBO_LASTNAME,
        CREDITAPP_UBO_REQUIRED,
        CREDITAPP_UBO_TITLE,
        ENROLL_ENABLED,
        UPLOAD_DOC,
        UPLOAD_DOC_DESC,
        UPLOADED_DOC,
        UPLOADED_DOCS_DESC
    };

    @track totalPrice;
    editModeVar = true;
    provisionedValue;
    @track customer = {}; 
    @track customerStory = {};
    @track beneficialOwnerType = [];
    @track crossCustomer;
    
     // Personal Guarantor
    @track personalGuar={
        firstName:'',
        middleInitial:'',
        lastName:'',
        SocialSecurityNumber:'',
        SocialSecurityNumberForMasking:''
       
    };
   

   
    /* Params from Url */
   @track oppId = null;
    opportunityDataId;
    opportunityId;
    creationDate;
    errorResultSet;
    @track comments = '';

    //to showPersonal edit or readonly
    @track showPersonalEdit = true;

    customerInfoShow;

    // A counter to load the opportunity data
    opportunityDataReloaded = 0;
    queryAppStatusCount = 0;

    // A counter to load contact roles
    contactRolesReloaded = 0;

    // Beneficial owner type
    individualCheck;
    ownerCheck;
    boardCheck;

    // Disable Enroll in Financing Button 
    disableEnrollButton = true;

    isLoading = false;
    filesToShow2=false;

    @api isModalOpen = false;
    filesList2 = [];

    get owmnerShipOptions() {
        return [
            { label: 'Owner(s): The Individual(s), who owns, directly or indirectly, more than 25 percent of the company. This is the ultimate beneficial owner.', value: 'Owner(s)' },
            { label: 'Individual with Effective Control:  If ultimate beneficial owner cannot be determined, please provide the the individual in daily operational control of the company and is in charge of day-to-day-decision-making.', value: 'Individual' },
            { label: 'Board of Directors : If neither of the above apply, please provide the information on all members of the Board of Directors or the Executive Management Team.', value: 'Board of Directors' },
        ];
    }

    @api refresh = false;
    @api docType = 'Sales Support';
    @wire(getRelatedFilesByRecordId, {refresh: '$refresh', recordId: '$oppId', docType: '$docType'})
    wiredResult(provisionedValue){ 
        this.provisionedValue = provisionedValue;
        const {data, error } = provisionedValue;
        console.log('OppId',this.oppid);

        console.log('*******************************' + this.docType);
        if(data){ 
            console.log('wire fired');
            if (this.docType == 'Partner'){  //Partner
                this.filesList2 = Object.keys(data).map(item=>({
                "label":data[item],
                "value": item,
                "url":`/dllondemand/sfc/servlet.shepherd/document/download/${item}`,
                }))
                if (this.filesList2.length > 0){
                    this.filesToShow2 = true;
                }else{
                    this.filesToShow2 = false;
                }
                console.log(this.filesList2);
                
            }
            else{  //Sales Support
                 this.docType = 'Partner';  //cause this wire to fire
                 this.filesList = Object.keys(data).map(item=>({"label":data[item],
                "value": item,
                "url":`/dllondemand/sfc/servlet.shepherd/document/download/${item}` 
                }))
                if (this.filesList.length > 0)
                    this.filesToShow = true;
                console.log(this.filesList);

            }
        }
        if(error){ 
            console.log(error)
        }

       
    }
    closeModal(event){
        this.isModalOpen = false;

    }
//Address validation
    handleCustomerInfoShow(event) {
        console.log('insert event handler'+ JSON.stringify(event.detail));
        this.crossCustomer=event.detail;
        console.log('this.cust' +JSON.stringify(this.crossCustomer));

    }
//Address validation
    handleCreditAppRedirect(event) {
        console.log('In handlecreditappredirect');
            if (event.detail === 'refresh') {
                if (this.isCreditCheck) {
                    this.pageReference.attributes.recordId = this.oppId;
                    this[NavigationMixin.Navigate](
                        this.pageReference,
                        false
                    );
                    setTimeout(() => {location.reload()}, 1000);
                } else {
                    console.log('In handlecreditappredirect refresh');
                    //setTimeout(() => {
                    this[NavigationMixin.Navigate]({
                        type: 'standard__webPage',
                        attributes: {
                            url: '/dllondemand/s/opportunity/' + this.oppId
                        }
                    });
                    location.reload();
                    //}, 10);
                }
            } else {
                this.showToast('Error','Unsuccessful redirect to credit application page', 'error');
            }
        }

    deleteDocument(event){
    
        this.isModalOpen = false;
 
        this.isLoading = true;
         
        deleteContentDocument ({recordId : this.deleteRecordId})
        .then(result => {
            if (result == 'ok'){
                refreshApex(this.provisionedValue);
                const evt = new ShowToastEvent({
                    title: 'Succes',
                    message: 'The document has been successfully deleted!',
                    variant: 'success',
                    duration:5000,
                });
                this.dispatchEvent(evt);
                this.isLoading = false;
            }
            else{
                console.log('result is bad');
                const evt = new ShowToastEvent({
                    title: 'Error',
                    message: 'Failure!' + result,
                    variant: 'error',
                    duration:5000,
                });
                this.dispatchEvent(evt);
            }
            
        })
        .catch(error => {
            this.searchData = undefined;
            console.log('error =====> '+JSON.stringify(error));
            const evt = new ShowToastEvent({
                title: 'Error',
                message: 'Failure!' + error,
                variant: 'error',
                duration:5000,
                });
                this.dispatchEvent(evt);
        }) 

        
    }
   
    deleteDoc(event){
        var x = Number(event.currentTarget.id);
        this.deleteRecordId = this.filesList2[x].value;
        this.isModalOpen = true;
    }

    download(event){
        console.log('downloading...' + event.target.value) ;
        window.open(event.target.value,'_blank');
    }


    refreshPage(event){

        refreshApex(this.provisionedValue);
        
    }

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            console.log('currentPageReference::'+JSON.stringify(currentPageReference.attributes.recordId));
            console.log('currentPageReference.state::'+JSON.stringify(currentPageReference.state));
          
            this.oppId = currentPageReference.state.opptid;
            console.log('opptid' +this.oppId);
          }
    }

    connectedCallback(){
        getOpportunityField ({opportunityId: this.oppId, loadCount: this.opportunityDataReloaded})
         
        .then(data=> 
        {
            console.log('thendata' +JSON.stringify(data));
            // Page Status
            console.log('Sub-stage: ' + data.Sub_Stage__c);
            console.log('pghere');
            this.statusValue = data.Sub_Stage__c;
            this.submittedStatus = data.Sub_Stage__c;
            this.locationValue = data.Account.Name;
            this.applicationNameValue=data.Application_Number__c;
            if(data.Partner_Sales_Rep__r != null){
                this.salesRepValue = data.Partner_Sales_Rep__r.Name;
            } else{
                this.salesRepValue = '';
            }
            const formatter = new Intl.NumberFormat('en-US', {
                style: 'currency',
                currency: 'USD',
                minimumFractionDigits: 2
            })
          
            //finance story
            this.rateType=data.Rate_Type__c;
            this.financeTerm=data.Term__c;
            this.financeType=data.Lease_Type__c;
            this.advPayments=data.Advance_Payments__c;
            this.totalPrice = (data.Amount != null && data.Amount != undefined && data.Amount != '') ?  formatter.format(data.Amount.toFixed(2)) : '';

            // Transform frequency, couldn't do it via CSS
            if(data.Frequency__c == 'MONTHLY'){
                this.paymentFrequency = 'Monthly';
            } else if(data.Frequency__c == 'SEMIANNUAL'){
                this.paymentFrequency = 'Semiannual';
            } else if(data.Frequency__c == 'QUARTERLY'){
                this.paymentFrequency = 'Quarterly';
            } else if(data.Frequency__c == 'SKIP'){
                this.paymentFrequency = 'Skip';
            } else if(data.Frequency__c == 'UNEQUAL'){
                this.paymentFrequency = 'Unequal';
            } else {
                this.paymentFrequency = data.Frequency__c;
            }

            this.opportunityDataId=data.Id;
            this.opportunityId = data.Id;

            // accepted customer
            this.template.querySelectorAll('[data-id="acceptedCheckbox"]').checked = data.Customer_Authorization__c;

            // customer
           
            if(data.End_User__r != null){
                console.log('customer here' +JSON.stringify(data.End_User__r));
                this.customer ={
                    name:data.End_User__r.Name,
                    contact: data.End_User__r.Primary_Contact_Name__c,
                    phone: data.End_User__r.Phone,
                    BillingStreet: data.End_User__r.BillingStreet,
                    BillingCity: data.End_User__r.BillingCity,
                    BillingCountry: data.End_User__r.BillingCountry,
                    BillingPostalCode: data.End_User__r.BillingPostalCode,
                    BillingCounty:data.End_User__r.BillingCounty__c,
                    email: data.End_User__r.Email__c,
                    taxNumber: data.End_User__r.Tax_ID__c,
                    customerId: data.End_User__r.Id
                };
            }

            //customer story data
            this.customerStory={

                businessStructure: data.Business_Structure__c,
                yearsInBusiness: data.Years_in_Business__c,
                story: data.Customer_Story__c,
                customerStoryId: data.Id
            };

          
         

            //payment
          /*  this.payment={
                term:data.Term__c,
                interestRate: (data.Interest_Rate__c != null && data.Interest_Rate__c != undefined && data.Interest_Rate__c != '') ? data.Interest_Rate__c.toFixed(2) : '',
                residual:data.Residual_Amount__c,
                totalPayment: (data.Payment_Amount__c != null && data.Payment_Amount__c != undefined && data.Payment_Amount__c != '') ? '$'+ data.Payment_Amount__c.toFixed(2) : ''
            };

            this.beneficialOwnerType = data.Beneficial_Owner_Type__c;
            
            this.salesReplist.push({'label':data.Sales_Rep_Name__c, 'value':data.Sales_Rep_Name__c});

            if (data.Account) {
                this.locationList.push({'label':data.Account.Name, 'value':data.Account.Name});
            }
            
            this.applicationNameValue=data.Application_Number__c;
            if(data.Partner_Sales_Rep__r != null){
                this.salesRepValue = data.Partner_Sales_Rep__r.Name;
            } else{
                this.salesRepValue = '';
            }
            console.log('Sales Rep: ' + this.salesRepValue);

            if(data.Opportunity_Number__c != null){
                this.quoteNumberValue = data.Opportunity_Number__c;
            } else {
                this.quoteNumberValue = '';
            }

            if(this.assets[0].quoteId != null){
                this.linkQuote = true;
                console.log('If asset quoteId: ' + this.assets[0].quoteId);
            } else {
                this.linkQuote = false;
                console.log('Else asset quoteId: ' + this.assets[0].quoteId);
            }

            if (data.Account) {
                this.locationValue=data.Account.Name;
            }
            
            this.nicknameValue=data.Nickname__c;

            // Set the UI and maintain the state if it's saved again
            this.acceptedCheckbox = data.Customer_Authorization__c;
            this.customerStory.acceptedCheckbox = data.Customer_Authorization__c;

            this.endUserAccount = data.End_User__c;
            const startLocation = this.template.querySelector('.startLocation');
            if (startLocation) {
                startLocation.value = this.locationValue;
            }
            const startSalesRep = this.template.querySelector('.startSalesrep');
            if (startSalesRep) {
                startSalesRep.value = this.salesRepValue;
            }*/

        

               
                //this.loading = true;
                getRelatedPartyForOpp({oppId: this.oppId})
                    .then(result => {
                        console.log('thenresult' +JSON.stringify(result));

                        if(result){

                        this.showPersonalEdit = false;
                      //  this.activeSections = JSON.parse(JSON.stringify(this.activeSections));
                        let resultParsed = JSON.parse(result);
                        if (typeof resultParsed.First_Name__c !== 'undefined') {
                            this.personalGuar.firstName = resultParsed.First_Name__c;
                        }
                        if (typeof resultParsed.Last_Name__c !== 'undefined') {
                            this.personalGuar.lastName = resultParsed.Last_Name__c;
                        }
                        if (typeof resultParsed.Middle_Name__c !== 'undefined') {
                            this.personalGuar.middleInitial = resultParsed.Middle_Name__c;
                        }
                        let ssnFormated = '';
                        let ssnString = resultParsed.SSN_Encrypted__c.toString();
                        for (let i = 0; i < 9; i++) {
                            if ((i === 3) || (i === 5)) {
                                ssnFormated = ssnFormated + '-';
                            }
                            ssnFormated = ssnFormated + ssnString[i].toString();
                        }
                        this.personalGuar.SocialSecurityNumber = ssnFormated;
                        this.personalGuar.SocialSecurityNumberForMasking = '***-**-****';
                        this.personalGuar = JSON.parse(JSON.stringify(this.personalGuar));
                        console.log('done PG loading');
                        //this.loading = false;
                    }
                    }).catch(error => {
                      //  this.activeSections = JSON.parse(JSON.stringify(this.activeSections));
                        console.log('No personal guarentee found');
                        console.log(JSON.parse(JSON.stringify(error)));
                        //this.loading = false;
                    });


                
                   





            
        }
        ).catch(error=>{
            console.log('error_infopage' +JSON.stringify(error));
        })
		 getQuoteLineField({opportunityId: this.oppId})
   
       .then (data=> {

            this.assets = [];
            var assetLen=0;

            const formatter = new Intl.NumberFormat('en-US', {
                style: 'currency',
                currency: 'USD',
                minimumFractionDigits: 2
            })

            for(var i=0;i<data.length;i++) {
                assetLen=i+1;
                this.assets.push({
                    sectionName: 'asset'+assetLen,
                    assetHeading: 'Asset '+assetLen,
                    assetNo: assetLen,
                    isFirst: true,
                    makeValue:data[i].Make__c,
                    assetTypeValue:data[i].Asset_Type_ITA_Class__c,
                    modelValue:data[i].Model__c,
                    mastTypeValue:data[i].Mast_Type__c,
                    assetOperatingEnvironmentValue:data[i].Operating_Environment__c,
                    annualHoursValue:data[i].Annual_Hours__c,
                    batteryIncludedValue:data[i].Battery_Included__c,
                    numberOfUnitsValue:data[i].Number_of_Units__c.toString(),
                    unitSalesPriceValue: (data[i].Base_Unit_Sales_Price__c != null && data[i].Base_Unit_Sales_Price__c != undefined && data[i].Base_Unit_Sales_Price__c != '') ? formatter.format(data[i].Base_Unit_Sales_Price__c.toFixed(2)) : '',
                    subsidyValue:data[i].Subsidy__c,
                    assetId:data[i].Id,
                    quoteId: data[i].Quote__c // Used to map to submitCreditApp()
                });
            }

        })
		.catch(error=> {
			console.log('getQuoteLineField', JSON.stringify(error));

        })
		   getQuoteLineForAccessoryField({opportunityId: this.oppId})

       .then (data=> {
            this.loading=true;
            this.accessories = [];
            var accessoryLen=0;

            console.log('accessories', data);

            const formatter = new Intl.NumberFormat('en-US', {
                style: 'currency',
                currency: 'USD',
                minimumFractionDigits: 2
            })

            for(var i=0;i<data.length;i++) {
                accessoryLen=i+1;

                // Handle whether a related asset exists.
                var relatedModel = '';
                if(data[i].Related_Asset__c != null){
                    relatedModel = data[i].Related_Asset__r.Make__c + ' ' + data[i].Related_Asset__r.Model__c;
                } else {
                    relatedModel = '';
                }
                // Add the accessory to the list
                this.accessories.push({
                    accessoryHeading:       'Accessory '+accessoryLen,
                    accessoryId:            data[i].Id,
                    accessoryNo:            accessoryLen,
                    accessoryValue:         data[i].Model__c,
                    isFirst:                true,
                    numberofUnitsValue:     data[i].Number_of_Units__c.toString(),
                    relatedAssetValue:      relatedModel,
                    sectionName:            'Accessory'+accessoryLen,
                    unitSalesPriceValue:  (data[i].Base_Unit_Sales_Price__c != null && data[i].Base_Unit_Sales_Price__c != undefined && data[i].Base_Unit_Sales_Price__c != '') ?   formatter.format(data[i].Base_Unit_Sales_Price__c.toFixed(2)) : ''
                });
            }
            this.loading=false;

        })
	.catch(error=> {
           console.log('getQuoteLineField', JSON.stringify(error));
        })
    }


     // Save content show toast message and data store in js variable
     handleOnSave(){
       
        this.loading = true;
        var errorOccur=false;
       
            if ((this.personalGuar.firstName.length !== 0) || (this.personalGuar.lastName.length !== 0) || (this.personalGuar.middleInitial.length !== 0) || (this.personalGuar.SocialSecurityNumber.length !== 0)) {
                if ((this.personalGuar.firstName.length === 0) || (this.personalGuar.lastName.length === 0)) {
                    const evt = new ShowToastEvent({
                        title:      CREDITAPP_SUBMITTEDERROR_TITLE,
                        message:    'Please provide a complete name for your Personal Guarantee.',
                        variant:    'error',
                        duration:   20000
                    });
                    this.dispatchEvent(evt);
                    this.loading = false;
                    return;
                }
                if (this.personalGuar.SocialSecurityNumber.length !== 11) {
                    const evt = new ShowToastEvent({
                        title:      CREDITAPP_SUBMITTEDERROR_TITLE,
                        message:    'Please provide an eleven character SSN for your Personal Guarantee.',
                        variant:    'error',
                        duration:   20000
                    });
                    this.dispatchEvent(evt);
                    this.loading = false;
                    return;
                }
                if ((this.personalGuar.SocialSecurityNumber[3] !== '-') || (this.personalGuar.SocialSecurityNumber[6] !== '-')) {
                    const evt = new ShowToastEvent({
                        title:      CREDITAPP_SUBMITTEDERROR_TITLE,
                        message:    'Please use the - character to separate the SSN for your Personal Guarantee.',
                        variant:    'error',
                        duration:   20000
                    });
                    this.dispatchEvent(evt);
                    this.loading = false;
                    return;
                }
                for (let i = 0; i < this.personalGuar.SocialSecurityNumber.length; i++) {
                    if ((i === 3) || (i === 6)) {
                        continue;
                    }
                    if ((this.personalGuar.SocialSecurityNumber[i] > '9') || (this.personalGuar.SocialSecurityNumber[i] < '0')) {
                        const evt = new ShowToastEvent({
                            title:      CREDITAPP_SUBMITTEDERROR_TITLE,
                            message:    'Please only provide numbers in the SSN for your Personal Guarantee.',
                            variant:    'error',
                            duration:   20000
                        });
                        this.dispatchEvent(evt);
                        this.loading = false;
                        return;
                    }
                }
            }

            //call apex method for Related party save
            console.log('value of guar' +JSON.stringify(this.personalGuar));
            saveRelatedPartyForOpp({
                oppId: this.oppId, 
                firstName: this.personalGuar.firstName, 
                middleName: this.personalGuar.middleInitial, 
                lastName: this.personalGuar.lastName, 
                ssn: this.personalGuar.SocialSecurityNumber.split('-').join('')
                
            }).then(result => {
              
                if (result) {
                    const evt = new ShowToastEvent({
                        title: CREDITAPP_SAVED_TITLE,
                        message: CREDITAPP_SAVED_MESSAGE,
                        variant: 'success',
                        duration: 10000,
                    });
                    this.dispatchEvent(evt);
                    this.loading = false;
                } else {
                    this.loading = false;
                }  

 //save for cross corporate guarantor
            console.log('customer in addinfo ' +JSON.stringify(this.crossCustomer));
            saveRelatedPartyForOpp1({
                oppId: this.oppId, 
                firstName: this.crossCustomer.Name, 
                middleName: '', 
                lastName: '', 
                ssn: this.crossCustomer.Tax_ID__c
              
            }).then(result => {
              
                if (result) {
                    const evt = new ShowToastEvent({
                        title: CREDITAPP_SAVED_TITLE,
                        message: CREDITAPP_SAVED_MESSAGE,
                        variant: 'success',
                        duration: 10000,
                    });
                    this.dispatchEvent(evt);
                    this.loading = false;
                } else {
                    this.loading = false;
                }  
            });


                 //save Comments 
         console.log('this.comm ' +JSON.stringify(this.comments));
            saveComments({
                oppId: this.oppId, 
                comments: this.comments
              
            }).then(result => {
                
                if (result) {
                   
                    this.loading = false;
                } else {
                    this.loading = false;
                }  
            });
        



            });


           
    }


    handlePersonalGuaranteeFirstNameChange(event) {
        
        this.personalGuar.firstName = event.detail.value;
        console.log('1' +JSON.stringifythis.personalGuar);
        
    }

    handlePersonalGuaranteeMiddleInitialChange(event) {
        this.personalGuar.middleInitial = event.detail.value;
        console.log('2' +JSON.stringifythis.personalGuar);
    }

    handlePersonalGuaranteeLastNameChange(event) {
        this.personalGuar.lastName = event.detail.value;
        console.log('3' +JSON.stringifythis.personalGuar);
    }

    handlePersonalGuaranteeSSNEncryptedChange(event) {
        this.personalGuar.SocialSecurityNumber = event.detail.value;
        this.personalGuar.SocialSecurityNumberForMasking = event.detail.value;
        console.log('4' +JSON.stringifythis.personalGuar);
    }

 

    handleChangeSalesRep(event) {        
        this.salesRep = '';
        this.salesRepList = this.salesRepListBackup;
        event.target.inputValue = '';
        this.salesRep = this.salesRepList.find(element => element.value === event.target.value).label;
        this.salesRepId = event.target.value;
        this.salesRepValue = this.salesRep;
        this.customerStory.salesRepId = this.salesRepId;
        console.log(this.salesRepId);
        console.log('In change function');
        //console.log(JSON.parse(JSON.stringify(this.quoteObject)));

        if (this.isLoadedQuote) {
            return;
        }

        //console.log(JSON.parse(JSON.stringify(this.osidForSalesReps)));

        if (this.osidForSalesReps.length !== 0) {
            //console.log('1');
            for (let i = 0; i < this.osidForSalesReps.length; i++) {
                //console.log('2');
                if (event.target.value === this.osidForSalesReps[i].value) {
                    //console.log('3');
                    this.location = this.osidForSalesReps[i].osid;
                    this.customerStory.location = this.location;
                    this.customerStory.salesRepId = this.salesRepId;
                    let dummyEventSecond = {value: this.osidForSalesReps[i].osid, name: 'location'};
                    let dummyEvent = {target: dummyEventSecond};
                    this.handleChangeLocation(dummyEvent);
                    //console.log('Executed handleChangeLocation');
                }
            }
        }

        //console.log('finished change sales rep');
    }


    handleChangeLocation(event) {
        this.locationValue = this.siteList.find(element => element.value === event.target.value).label;

        this.customerStory.location = event.target.value;

        this.loading = true;

        this.refreshSalesRepDropdown = false;

        getSalesReps({ originatingSiteId: event.target.value })
            .then(result => {
                let data = JSON.parse(result);
                let sList = [];
                let currentSalesRep = this.salesRepId;
                let saveCurrentSalesRep = false;

                data.forEach(function(element){
                    if (currentSalesRep === element.id) {
                        saveCurrentSalesRep = true;
                    }
                    sList.push({label: element.name, value: element.id});

                });

                sList.push({label: 'None', value: ''});

                //this.salesRepList = sList;

                if (!saveCurrentSalesRep) {
                    console.log('sales rep removed');
                    //this.salesRepList = JSON.parse(JSON.stringify(this.salesRepList));
                    this.salesRep = '';
                    this.salesRepId = '';
                    //this.quoteObject.salesRep = '';
                }

                this.refreshSalesRepDropdown = true;

                console.log('getSalesReps Done');
                console.log(JSON.parse(JSON.stringify(sList)));
                this.loading = false;


            })
            .catch(error => {
                this.loading = false;
                this.showToast('Something went wrong', error.body.message, 'error');
            });
    }

  
    //toggle for sections
    handleSectionToggle(event) {
        const openSections = event.detail.openSections;
        this.openAccordionSections = event.detail.openSections;
        if (openSections.length === 0) {
            this.activeSectionsMessage = 'All sections are closed';
        } else {
            this.activeSectionsMessage =
                'Open sections: ' + openSections.join(', ');
        }
    }

    //Resubmit comments
    handleResubmitComm(event){
        this.comments =event.target.value;
    }

    //CODE for ssn masking
    ssnOnFocus(event) {
        var dataIdVar = event.target.name;
        this.template.querySelector(`[data-id="${dataIdVar}"]`).value = this.personalGuar.SocialSecurityNumber;
    }

    ssnOnBlur(event) {
        var dataIdVar = event.target.name;

        if(this.template.querySelector(`[data-id="${dataIdVar}"]`).value == '' || this.template.querySelector(`[data-id="${dataIdVar}"]`).value == null){
            this.personalGuar.SocialSecurityNumber = '';
        }

        // Only display masking fields if a date had been selected.
        if((typeof this.personalGuar.SocialSecurityNumber !== 'undefined') && (this.personalGuar.SocialSecurityNumber.length !== 0)){
            this.template.querySelector(`[data-id="${dataIdVar}"]`).value = '***-**-****';
        }
    }

    isSSN(){
        if(this.personalGuar.SocialSecurityNumber.length !== 0){
            isSSN = true;
        } else {
            isSSN = false;
        }
    }  

}