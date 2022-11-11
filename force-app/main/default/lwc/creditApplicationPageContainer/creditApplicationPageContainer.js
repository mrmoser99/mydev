/**
 * @description       : LWC component to Credit Application Page container. 
 * @author            : Kritika Sharma : Traction on Demand
 * @group             : Kritika Sharma & Surbhi Goyal :  Traction on Demand
 * @last modified on  : 11-09-2022
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Changes Log        :
 * Date       - BUG/PBI    - Author                   - Description
 * 09/14/2022 - BUG 860568 - Fernando Nereu de Souza  - As a credit check I want to create an opportunity only when save or submit is selected 
 * 09/21/2022 - BUG 809443 - Lucas Silva              - Systematically drop anything other than numbers comma and decimal from the Dollar amount input
 * 09/22/2022 - BUG 855960 - Fernando Nereu de Souza  - Nothing should appear in the SSN box if no data was captured
 * 10/07/2022 - BUG 855965 - Lucas Silva              - The DOB appearing under the UBO section in "review" mode is not masked
 * 11/02/2022 -              Mark Moser               - Fix performance of waiting for credit response
**/
import createNewOppForCreditCheck from '@salesforce/apex/CreditApplicationHeaderController.createNewOppForCreditCheck';
import getRelatedPartyForOpp from '@salesforce/apex/CreditApplicationHeaderController.getRelatedPartyForOpp';
import saveRelatedPartyForOpp from '@salesforce/apex/CreditApplicationHeaderController.saveRelatedPartyForOpp';
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
import { refreshApex } from '@salesforce/apex';


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
//platform event import
import { loadScript } from 'lightning/platformResourceLoader';
import cometd from '@salesforce/resourceUrl/cometd';
import getSessionId from '@salesforce/apex/GenericUtilityClass.getSessionId';

export default class CreditApplicationPageContainer extends NavigationMixin(LightningElement){
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
        ENROLL_ENABLED
    };
    
    
    //platform event
    @api channel = '/event/Credit_Response__e';;
    libInitialized = false;
    sessionId;
    error;


    //active section
    //activeSections = ['Financing Structure','Beneficial Owner 1','asset 1','Customer Information','Customer Story (Optional)','qwnershipInformation','Personal Guarantee (Optional)']; 
    activeSections = ['Financing Structure']; 
    /* Params from Url */
    oppId = null;
    opportunityDataId;
    opportunityId;
    creationDate;
    errorResultSet

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

    //customerTrue=false;
    
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            console.log('currentPageReference::'+JSON.stringify(currentPageReference.attributes.recordId));
            console.log('currentPageReference.state::'+JSON.stringify(currentPageReference.state));
            // Only the standard opportunity page is being used now.
            this.oppId = currentPageReference.attributes.recordId;
            
            // The read/write page layouts are hidden by default, but then modified based on the opportunity status.
            this.appEditMode = 'hide';

            // creates an opp every time you enter the page for credit check
            /*Start: PBI 860568 - Fernando Nereu de Souza  - As a credit check I want to create an opportunity only when save or submit is selected 
            if (window.location.pathname.includes('credit-check') && (typeof this.oppId === 'undefined') && (Object.keys(currentPageReference.state).length === 0)) {            
                createNewOppForCreditCheck({'location' : ''})
                    .then(result => {
                        this.isCreditCheck = true;
                        this.oppId = result;
                        this.customerStory.customerStoryId = result;
                        console.log('Success making new Opp:'+this.oppId);
                    })
                    .catch(error => {
                        console.log('Error initializing credit check');
                        this.showToast('Error initializing credit check', 'No opp id provided and when an opp was made, it failed', 'error');
                    });
            }
            END: PBI 860568 - Fernando Nereu de Souza  - As a credit check I want to create an opportunity only when save or submit is selected */
        }
    }
    

    //status value on header after submit
    submittedStatus='';
    //Model Pop-up on click of cancel button
    isModalOpen = false;
    // public property
    @api sectionTitle;
    @api sectionSubTitle;

    isCreditCheck = 'hide';
    refreshCustomerQuickSearch = true; 
    isAmountDisabled = false;

    // UBO options
    titlePicklist;
    dateOfBirthPicklist;
    countryOfResidencePicklist;
    ownershipPercentagePicklist;
    hasBeneficialOwner = 0;

    //Object model
    applicationNameValue;
    quoteNumberValue;
    salesRepValue;
    nicknameValue;
    locationValue;
    statusValue;
    locationList=[];
    salesReplist=[];
    accordionSection = 0;
    createOpportunity = 0;

    benefitOwner;
    //finance structure
    rateType;
    financeTerm;
    financeType;
    paymentFrequency;
    advPayments;
    totalPrice;
    rateTypePicklist;
    financeTermPicklist;
    financeTypePicklist;
    frequencyPicklist;
    advancedPaymentsPicklist;
    //assets
    assets = [{
        sectionName: 'asset 1',
        assetHeading: 'Asset 1',
        assetNo: 1,
        isFirst: true,
        makeValue:'',
        assetTypeValue:'',
        modelValue:'',
        mastTypeValue:'',
        assetOperatingEnvironmentValue:'',
        annualHoursValue:'',
        batteryIncludedValue:'',
        numberOfUnitsValue:'',
        unitSalesPriceValue:'',
        subsidyValue:'',
        assetId:''
    }];

    // asset picklist options
    makePicklist;
    assetTypePicklist;
    modelPicklist;
    mastTypePicklist;
    assetOperatingPicklist;
    batteryIncludedPicklist;
    numberOfUnitsPicklist;
    subsidyPicklist;
    assetsBlank= [];
    loading=false;
    //accessory
    accessories = [{
        sectionName: 'Accessory1',
        accessoryHeading: 'Accessory 1',
        accessoryNo: 1,
        isFirst: true,
        relatedAssetValue:'',
        accessoryValue:'',
        unitSalesPriceValue:'',
        numberofUnitsValue:'',
        accessoryId:''
    }];
    //accesssory picklist options
    relatedAssetPicklist;
    accessoryPicklist;
    unitSalesPricePicklist;
    numberofUnitsPicklist;

    // Personal Guarantor
    personalGuar={
        firstName:'',
        middleInitial:'',
        lastName:'',
        SocialSecurityNumber:'',
        SocialSecurityNumberForMasking:''
    };
0
    // Beneficial Owner
    beneficialOwner=[{
        ownerHeading:'Beneficial Owner 1',
        ownerNo:1,
        firstName:'',
        middleName:'',
        lastName:'',
        titleValue:'',
        dateOfBirthValue:'',
        dobEmptyCheck: true,
        countryOfResidenceValue:'',
        ownershipPercentageValue:'',
        //uboID:'',
        endUserAccount: ''
    },{
        ownerHeading:'Beneficial Owner 2',
        ownerNo:2,
        firstName:'',
        middleName:'',
        lastName:'',
        titleValue:'',
        dateOfBirthValue:'',
        dobEmptyCheck: true,
        countryOfResidenceValue:'',
        ownershipPercentageValue:'',
        //uboID:'',
        endUserAccount: ''
    },{
        ownerHeading:'Beneficial Owner 3',
        ownerNo:3,
        firstName:'',
        middleName:'',
        lastName:'',
        titleValue:'',
        dateOfBirthValue:'',
        dobEmptyCheck: true,
        countryOfResidenceValue:'',
        ownershipPercentageValue:'',
        //uboID:'',
        endUserAccount: ''
    },{
        ownerHeading:'Beneficial Owner 4',
        ownerNo:4,
        firstName:'',
        middleName:'',
        lastName:'',
        titleValue:'',
        dateOfBirthValue:'',
        dobEmptyCheck: true,
        countryOfResidenceValue:'',
        ownershipPercentageValue:'',
        //uboID:'',
        endUserAccount: ''
    }];
    //customer story
    customerStory={
    };
    //customer Info
    customer ={
    };
    //summary
    summary={
    };
    //payment
    payment={
    };

    customerInfoShow;
    beneficialOwnerType = '';

    salesRep;
    salesRepId;

    get owmnerShipOptions() {
        return [
            { label: 'Owner(s): The Individual(s), who owns, directly or indirectly, more than 25 percent of the company. This is the ultimate beneficial owner.', value: 'Owner(s)' },
            { label: 'Individual with Effective Control:  If ultimate beneficial owner cannot be determined, please provide the the individual in daily operational control of the company and is in charge of day-to-day-decision-making.', value: 'Individual' },
            { label: 'Board of Directors : If neither of the above apply, please provide the information on all members of the Board of Directors or the Executive Management Team.', value: 'Board of Directors' },
        ];
    }

    get businessStructureOptions() {
        return [
            { label: 'Corporation', value: 'Corporation' },
            { label: 'Limited Liability Company (LLC)', value: 'Limited Liability Company (LLC)' },
            { label: 'Non-Profit', value: 'Non-Profit' },
            { label: 'Others', value: 'Others' }
        ];
    }

    hasQuotes = true;
    hasQuotesCreditCheck = false;

    siteList = [];
    salesRepList = [];
    osidForSalesReps = [];

    @wire(getUserSite, {userId: null})
    wiredgetUserSite({error, data}) {
        this.loading = true;
        console.log('hasBeneficialOwner::'+ this.hasBeneficialOwner);
        if(this.hasBeneficialOwner == 0) {
            this.beneficialOwner = [];
        }
        this.beneficialOwnerType = null;
        //this.advance = '0';
        //this.frequency = 'monthly';
        console.log('in getUserSite');

        if (data) {
            let parsedData = JSON.parse(data);
            console.log(JSON.parse(JSON.stringify(data)));
            let osidObj = {osidArray: []};
            //this.location = parsedData.returnSiteList[0].originatingSiteId;
            //this.userSite = parsedData.returnSiteList[0].originatingSiteId;
            for (let i = 0; i < parsedData.returnSiteList.length; i++) {
                this.siteList.push({label: parsedData.returnSiteList[i].name, value: parsedData.returnSiteList[i].originatingSiteId});
                osidObj.osidArray.push(parsedData.returnSiteList[i].originatingSiteId);
            }
            this.siteList = JSON.parse(JSON.stringify(this.siteList));
            if ((this.salesRepList.length === 0) && !this.isLoadedQuote) {
                getSalesRepsFromReturnedOSID({osidJSON:  JSON.stringify(osidObj)})
                    .then(result => {

                        let data = JSON.parse(result);
                        let sList = [];
                        let osidList = [];

                        data.forEach(function (element) {

                            sList.push({label: element.name, value: element.id});
                            osidList.push({osid: element.osid, value: element.id});

                        });

                        sList.push({label: 'None', value: ''});

                        this.salesRepList = sList;
                        this.salesRepListBackup = sList;
                        console.log('getSalesRepsOSID Done');
                        console.log(JSON.parse(JSON.stringify(sList)));
                        this.osidForSalesReps = osidList;
                        this.loading = false;
                        this.hasLocationSelectionSalesRep = false;
                    }).catch(error => {
                    this.loading = false;
                    this.showToast('Something went wrong', error.body.message, 'error');
                });
                return;
            }
            //this.quoteObject.userSite = parsedData.returnSiteList[0].originatingSiteId;
        } else if (error) {
            this.showToast('Something went wrong', error.body.message, 'error');
            this.location = undefined;
        }
        setTimeout(() => {
            this.loading = false;

            console.log('wiredGetUserSite done');
        }, 1500);
    }

    @wire(getContactField, {opportunityId: '$oppId', loadCount: '$contactRolesReloaded'})
    wiredGetContact({ error, data }){
        if (data) {
            this.beneficialOwner = [];
            var ownerLen=0;

            for(var i=0;i<data.length;i++) {
                ownerLen=i+1;
                var auxDOBcheck = data[i].Birthdate_Encrypted__c == null ?  true : false; // BUG 855965 - Lucas Silva
                this.beneficialOwner.push({
                    ownerHeading:                   'Beneficial Owner '+ownerLen,
                    endUserAccount:                 data[i].AccountId,
                    ownerNo:                        ownerLen,
                    firstName:                      data[i].FirstName,
                    middleName:                     data[i].MiddleName,
                    lastName:                       data[i].LastName,
                    titleValue:                     data[i].Title,
                    dateOfBirthValue:               data[i].Birthdate_Encrypted__c,
                    dateOfBirthValueForMasking:     '********',
                    dobEmptyCheck:                  auxDOBcheck,
                    countryOfResidenceValue:        data[i].UBO_Country_of_Residence__c,
                    ownershipPercentageValue:       data[i].Account_Ownership_Percentage__c,
                    uboID:                          data[i].Id
                });
                this.hasBeneficialOwner = ownerLen;
            }
        }else if (error) {
            this.beneficialOwner = [];
        }
        //setTimeout(() => {location.reload()}, 1000);      
    }

    @wire(getQuoteLineField, {opportunityId: '$oppId'})
    wiredGetQuoteLine({ error, data }){
        if (data) {

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

        } else if (error) {

        }
    }
    @wire(getQuoteLineForAccessoryField, {opportunityId: '$oppId'})
    wiredGetQuoteLineForAccessory({ error, data }){
        if (data) {
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

        } else if (error) {

        }
    }


    @wire(getOpportunityField, {opportunityId: '$oppId', loadCount: '$opportunityDataReloaded'})
    wiredgetQuoteRecord({ error, data }) {

        if (data) {
            console.log('in get wired ');
            // Page Status
            console.log('Sub-stage: ' + data.Sub_Stage__c);
            this.statusValue = data.Sub_Stage__c;
            this.submittedStatus = data.Sub_Stage__c;
            if(data.Sub_Stage__c == 'Application Draft'){
                this.appEditMode = true;
            } else {
                this.appEditMode = false;
            }
            //Enable Enroll in Financing button
            if(ENROLL_ENABLED == 'false') {
                this.disableEnrollButton = true;
            } else if (data.Sub_Stage__c=='Application Approved' || data.Sub_Stage__c=='Conditional Approval'|| data.Sub_Stage__c=='Document Request Draft'
                || data.Sub_Stage__c=='Documents Requested' || data.Sub_Stage__c=='Documents Out'|| data.Sub_Stage__c=='Documents In'
                || data.Sub_Stage__c=='Purchase Order Issued'|| data.Sub_Stage__c=='Invoice Received'
                || data.Sub_Stage__c=='Delivery and Acceptance Received'|| data.Sub_Stage__c=='Prep for Funding'
                || data.Sub_Stage__c=='Passed to Funding'|| data.Sub_Stage__c=='Funding Team Accepted'){
                this.disableEnrollButton = false;
            } else {
                this.disableEnrollButton = true;
            }

            const formatter = new Intl.NumberFormat('en-US', {
                style: 'currency',
                currency: 'USD',
                minimumFractionDigits: 2
            })
            //ownership info 
            if(data.Beneficial_Owner_Type__c != null && data.Beneficial_Owner_Type__c != undefined && data.Beneficial_Owner_Type__c != '') {
                this.beneficialOwnerType=data.Beneficial_Owner_Type__c;
            } else {
                this.beneficialOwnerType='';
            }
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

            // Beneficial Owners
            this.benefitOwner = data.Beneficial_Owner_Type__c;
            this.customerStory.beneficialOwnerType = data.Beneficial_Owner_Type__c;

            // The checkboxes are only used in the edit page
            if(this.appEditMode == true){
                if(this.customerStory.beneficialOwnerType=="Owner(s)"){
                    this.template.querySelector(`[data-id="Owner"]`).checked=true;
                } else if(this.customerStory.beneficialOwnerType=="Individual"){
                    this.template.querySelector(`[data-id="Individual"]`).checked=true;
                } else if(this.customerStory.beneficialOwnerType=="Board of Directors"){
                    this.template.querySelector(`[data-id="boardofDirectors"]`).checked=true;
                }
            }
            
            //summary
            this.summary={
                leaseTypeSummary:data.Lease_Type__c,
                rateTypeSummary:data.Rate_Type__c,
                advancedPaymentsSummary:data.Advance_Payments__c,
                totalPriceSummary:formatter.format(data.Amount),
            };

            //payment
            this.payment={
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

            if(this.assets.length > 0 ) {
                if(this.assets[0].quoteId != null){
                    this.linkQuote = true;
                } else {
                    this.linkQuote = false;
                }        
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
            }

            // Credit Check
            if (data.Type === 'Credit Check') {
                console.log('in data isCreditCheck');
                this.isCreditCheck = true;
                this.totalPrice = data.Amount;
                this.salesRep = this.salesRepValue;
                //this.applicationNameValue = data.Pre_Qualification_Application_Number__c;
                if (data.Account) {
                    this.location = data.Account.Originating_Site_ID__c;
                }
            } else {
                this.isCreditCheck = false;
                //this.loading = true;
                getRelatedPartyForOpp({oppId: this.oppId})
                    .then(result => {
                        this.activeSections = JSON.parse(JSON.stringify(this.activeSections));
                        let resultParsed = JSON.parse(result);
                        this.personalGuar.firstName = resultParsed.First_Name__c;
                        this.personalGuar.lastName = resultParsed.Last_Name__c;
                        this.personalGuar.middleInitial = resultParsed.Middle_Name__c;
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
                    }).catch(error => {
                        this.activeSections = JSON.parse(JSON.stringify(this.activeSections));
                        console.log('No personal guarentee found');
                        console.log(JSON.parse(JSON.stringify(error)));
                        //this.loading = false;
                    });
            }
        }
    }

    connectedCallback(){

     

        // All three of the following arrays have to maintain their exact order and count as they map to the same index in each array.
        var fieldOptions=['Rate_Type__c','Finance_Term_Month__c','Lease_Type__c','Payment_Frequency__c','Advance_Payments__c',
            'Make__c','Asset_Type_ITA_Class__c','Model__c','Mast_Type__c','Operating_Environment__c','Battery_Included__c','Number_of_Units__c','Subsidy__c',
            'Name','Model__c','Base_Unit_Sales_Price__c','Number_of_Units__c',
            'Title','Birthdate_Encrypted__c','UBO_Country_of_Residence__c','Account_Ownership_Percentage__c'];
        var objectOptions=['Quote','Quote','Quote','Quote','Quote',
            'Quote_Line__c','Quote_Line__c','Quote_Line__c','Quote_Line__c','Quote_Line__c','Quote_Line__c','Quote_Line__c','Quote_Line__c',
            'Quote_Line__c','Quote_Line__c','Quote_Line__c','Quote_Line__c',
            'Contact','Contact','Contact','Contact'];
        var nameOptions=['this.rateTypePicklist','this.financeTermPicklist','this.financeTypePicklist','this.frequencyPicklist','this.advancedPaymentsPicklist',
            'this.makePicklist','this.assetTypePicklist','this.modelPicklist','this.mastTypePicklist','this.assetOperatingPicklist','this.batteryIncludedPicklist','this.numberOfUnitsPicklist','this.subsidyPicklist',
            'this.relatedAssetPicklist','this.accessoryPicklist','this.unitSalesPricePicklist','this.numberofUnitsPicklist',
            'this.titlePicklist','this.dateOfBirthPicklist','this.countryOfResidencePicklist','this.ownershipPercentagePicklist'];
        
        for(var i=0;i<fieldOptions.length;i++) {
            createPickListValues({objectName:objectOptions[i],fieldName:fieldOptions[i]}).then(result =>{
                if(result){
                    //console.log('result:::'+JSON.stringify(result));
                    let options = [];
                    for(var key in result){
                        options.push({'label':result[key], 'value':key});
                    }
                    if(nameOptions[i]==this.rateTypePicklist) {
                        this.rateTypePicklist=options;
                    } else if(nameOptions[i]==this.financeTermPicklist) {
                        this.financeTermPicklist=options;
                    } else if(nameOptions[i]==this.financeTypePicklist) {
                        this.financeTypePicklist=options;
                    } else if(nameOptions[i]==this.frequencyPicklist) {
                        this.frequencyPicklist=options;
                    } else if(nameOptions[i]==this.advancedPaymentsPicklist) {
                        this.advancedPaymentsPicklist=options;
                    } else if(nameOptions[i]==this.makePicklist) {
                        this.makePicklist=options;
                    } else if(nameOptions[i]==this.assetTypePicklist) {
                        this.assetTypePicklist=options;
                    } else if(nameOptions[i]==this.modelPicklist) {
                        this.modelPicklist=options;
                    } else if(nameOptions[i]==this.mastTypePicklist) {
                        this.mastTypePicklist=options;
                    } else if(nameOptions[i]==this.assetOperatingPicklist) {
                        this.assetOperatingPicklist=options;
                    } else if(nameOptions[i]==this.batteryIncludedPicklist) {
                        this.batteryIncludedPicklist=options;
                    } else if(nameOptions[i]==this.numberOfUnitsPicklist) {
                        this.numberOfUnitsPicklist=options;
                    } else if(nameOptions[i]==this.subsidyPicklist) {
                        this.subsidyPicklist=options;
                    }  else if(nameOptions[i]==this.relatedAssetPicklist) {
                        this.relatedAssetPicklist=options;
                    } else if(nameOptions[i]==this.accessoryPicklist) {
                        this.accessoryPicklist=options;
                    } else if(nameOptions[i]==this.unitSalesPricePicklist) {
                        this.unitSalesPricePicklist=options;
                    } else if(nameOptions[i]==this.numberofUnitsPicklist) {
                        this.numberofUnitsPicklist=options;
                    }  else if(nameOptions[i]==this.titlePicklist) {
                        this.titlePicklist=options;
                    } else if(nameOptions[i]==this.dateOfBirthPicklist) {
                        this.dateOfBirthPicklist=options;
                    } else if(nameOptions[i]==this.countryOfResidencePicklist) {
                        this.countryOfResidencePicklist = options;
                    } else if(nameOptions[i]==this.ownershipPercentagePicklist) {
                        this.ownershipPercentagePicklist=options;
                    }
                }
            });
           
        }
        refreshApex(this.getContactField);
        
    }

    handlePersonalGuaranteeFirstNameChange(event) {
        this.personalGuar.firstName = event.detail.value;
    }

    handlePersonalGuaranteeMiddleInitialChange(event) {
        this.personalGuar.middleInitial = event.detail.value;
    }

    handlePersonalGuaranteeLastNameChange(event) {
        this.personalGuar.lastName = event.detail.value;
    }

    handlePersonalGuaranteeSSNEncryptedChange(event) {
        this.personalGuar.SocialSecurityNumber = event.detail.value;
        this.personalGuar.SocialSecurityNumberForMasking = event.detail.value;
    }

    isLoadedQuote = false;

    location = '';

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

    refreshSalesRepDropdown = false;

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
                this.accordionSection = 1;
                console.log(JSON.parse(JSON.stringify(sList)));
                this.loading = false;


            })
            .catch(error => {
                this.loading = false;
                this.showToast('Something went wrong', error.body.message, 'error');
            });
    }

    //Start: BUG 809443 - Lucas Silva - Systematically drop anything other than numbers comma and decimal from the Dollar amount input
    handleChangeFinanceAmount(event) {
        let trimmedPrice = this.removeInvalidPriceCharacters(event.target.value); 
        let noCentsValue = false;
        trimmedPrice = trimmedPrice.split('.');
        if (trimmedPrice.length === 0) {          
            trimmedPrice = 0;
        } else if (trimmedPrice.length === 1) {
            noCentsValue = true;
            trimmedPrice = parseInt(trimmedPrice[0]);       
        } else {
            if (trimmedPrice[1].length > 1) {
                trimmedPrice = trimmedPrice[0] + '.' + trimmedPrice[1].substring(0, 2);
            } else if (trimmedPrice[1].length === 1) {
                trimmedPrice = trimmedPrice[0] + '.' + trimmedPrice[1];
            } else {
                trimmedPrice = trimmedPrice[0] + '.';
            }
        }
        this.customerStory.amount = parseFloat(trimmedPrice).toFixed(2).toString(); 
        console.log('this.customerStory.amount: '+this.customerStory.amount);
    }

    formatCurrencyForInput(event) {
        if (event.target.value.length !== 0) {
            this.template.querySelector(`[data-id="${event.target.name}"]`).value = '$' + this.formatCurrency(event.target.value);
            this.accordionSection +=1;
            console.log('accordionSection::'+ this.accordionSection);
            this.handleSectionToggle(); 
        }
    }
    
    formatCurrency(str) {
        let result = this.removeInvalidPriceCharacters(str).split('.');
        let returnValue = '';
        let currentStep = 0;
        for (let i = result[0].length - 1; i >= 0; i--) {
            returnValue = result[0][i] + returnValue;
            currentStep++;
            if ((currentStep === 3) && (i !== 0)) {
                returnValue = ',' + returnValue;
                currentStep = 0;
            }
        }
        if ((result.length > 1) && (result[1].length !== 0)) {
            if (result[1].length === 1) {
                returnValue = returnValue + '.' + result[1];
            } else {
                returnValue = returnValue + '.' + result[1].substring(0, 2);
            }
        }
        if(!returnValue.includes('.')){
            returnValue = returnValue + '.00';        
        }
        return returnValue;
    }

    removeInvalidPriceCharacters(str) {
        let returnStr = '';
        for (let i = 0; i < str.length; i++) {
            if ((str[i] >= '0') && (str[i] <= '9')) {
                returnStr += str[i];
            } else if (str[i] === '.') {
                returnStr += '.';
            }
        }
        return returnStr;
    }
    //End: BUG 809443 - Lucas Silva - Systematically drop anything other than numbers comma and decimal from the Dollar amount input

    //toggle for sections
    handleSectionToggle(event) {
        if (this.accordionSection >= 2) {
            this.activeSections = ['Financing Structure','Beneficial Owner 1','Customer Information','Customer Story (Optional)','qwnershipInformation','Personal Guarantee (Optional)', 'CustomerApproval', 'Beneficial Owner 2', 'Beneficial Owner 3', 'Beneficial Owner 4']; 
            this.createOpportunity +=1;
            console.log("customerStoryId::"+this.customerStory.customerStoryId);
            console.log("this.oppId::"+this.oppId);
            
            if (this.createOpportunity == 1) {
                this.handleOnSave();
                /*this.loading = true;
                createNewOppForCreditCheck({'location' : this.customerStory.location, 'amount': this.customerStory.amount})
                .then(result => {
                    this.isCreditCheck = true;
                    this.oppId = result;
                    this.customerStory.customerStoryId = result;
                    console.log('Success making new Opp:'+this.oppId);
                    this.loading = false;
                })
                .catch(error => {
                    console.log('Error initializing credit check');
                    this.showToast('Error initializing credit check', 'No opp id provided and when an opp was made, it failed', 'error');
                    this.loading = false;
                });
                
                if(this.beneficialOwner.length != 0){
                    let anyDuplicates = this.validBeneficialOwner(this.beneficialOwner);
                    console.log('anyDuplicates::'+ anyDuplicates);
                    if(anyDuplicates == false) {
                        UpdateBenefitOwnerData({
                            benefitOwner: this.beneficialOwner,
                            opportunityId: this.oppId
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
                        })   
                    }             
                }*/
            }
        }        
    }


/*
    @api
    customerInfoSectionHide(){
        this.customerTrue=false;
    }
*/
    addNewAsset() {
        this.loading=true;
        var assetsSize=this.assets.length+1;
        this.assets.push({
            sectionName: 'asset'+assetsSize,
            assetHeading: 'Asset '+assetsSize,
            assetNo: assetsSize,
            isFirst: true
        });
        this.loading=false;

    }

    addNewAccessory() {
        this.loading=true;
        var accessorySize=this.accessories.length+1;
        this.accessories.push({
            sectionName: 'Accessory'+accessorySize,
            accessoryHeading: 'Accessory '+accessorySize,
            accessoryNo: accessorySize,
            isFirst: true
        });
        this.loading=false;

    }

    removeAsset(event) {
        var newAssets=[];
        var assetLen=0;
        for(var i=0;i<this.assets.length;i++) {
            assetLen=assetLen+1;
            if(this.assets[i].assetNo==event.target.dataset.item) {
                assetLen=assetLen-1;
            } else {
                this.assets[i].sectionName='asset'+assetLen;
                this.assets[i].assetHeading='Asset '+assetLen;
                this.assets[i].assetNo=assetLen;
                newAssets.push(this.assets[i]);
            }
        }
        this.assets=newAssets;
    }

    removeAccessory(event) {
        var newAccessory=[];
        var accessoryLen=0;
        for(var i=0;i<this.accessories.length;i++) {
            accessoryLen=accessoryLen+1;
            if(this.accessories[i].accessoryNo==event.target.dataset.item) {
                accessoryLen=accessoryLen-1;
            } else {
                this.accessories[i].sectionName='Accessory'+accessoryLen;
                this.accessories[i].accessoryHeading='Accessory '+accessoryLen;
                this.accessories[i].accessoryNo=accessoryLen;
                newAccessory.push(this.accessories[i]);
            }
        }
        this.accessories=newAccessory;
    }

    validBeneficialOwner(beneficialOwner){
        if(beneficialOwner.length != 0) {
            let areAnyDuplicates = false;

            beneficialOwner.map(function(obj) {
                return obj.firstName + obj.lastName + obj.middleName + obj.titleValue + obj.dateOfBirthValue;
            }).forEach(function (element, index, arr) {
                if (arr.indexOf(element) !== index) {
                    areAnyDuplicates = true;
                }
            });
    
            if(areAnyDuplicates == true){
                const evt = new ShowToastEvent({
                    title: 'Error',
                    message: 'Please enter a unique individual per Beneficial Owner Section',
                    variant: 'error',
                    duration: 20000
                })
                this.dispatchEvent(evt);
                errorOccur=true;
            }
            return areAnyDuplicates;
        } else {
            let areAnyDuplicates = false;
            return areAnyDuplicates;
        }
    }

    openProposal() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: window.location.origin + '/dllondemand/s/new-quote?oppid=' + this.oppId
            }
        })
    }

    addBeneficalOwner() {
        this.loading=true;
        var boSize=this.beneficialOwner.length+1;
        this.beneficialOwner.push({
            ownerHeading:'Beneficial Owner '+boSize,
            ownerNo:boSize,
            firstName:'',
            middleName:'',
            lastName:'',
            titleValue:'',
            dateOfBirthValue:'',
            dobEmptyCheck: true,
            countryOfResidenceValue:'',
            ownershipPercentageValue:'',
            endUserAccount: this.endUserAccount
        });
        this.loading=false;
    }
    clearCustomer(){
        //delete customer information by apex
    }

    // --------------------------------- model pop-up on click of cancel button--------------------------//
    openModal() {
        // to open modal set isModalOpen tarck value as true
        this.isModalOpen = true;
    }
    closeModal() {
        // to close modal set isModalOpen tarck value as false
        this.isModalOpen = false;
    }



    submitDetails() {
        // to close modal set isModalOpen tarck value as false
        //Add your code to call apex method or do some processing
        location.reload();
        this.isModalOpen = false;
    }

    isValidValues(){
        var isValid=true;
        let inputFields = this.template.querySelectorAll('.validate');
        inputFields.forEach(inputField => {
            if(!inputField.checkValidity()) {
                inputField.reportValidity();
                isValid = false;
            }
        });
        return isValid;
    }

    //Start: BUG 855960 - Fernando Nereu de Souza - Nothing should appear in the SSN box if no data was captured
    isSSN(){
        if(this.personalGuar.SocialSecurityNumber.length !== 0){
            isSSN = true;
        } else {
            isSSN = false;
        }
    }
    //End: BUG 855960 - Fernando Nereu de Souza - Nothing should appear in the SSN box if no data was captured

    // Save content show toast message and data store in js variable
    handleOnSave(){
        this.loading = true;
        var errorOccur=false;
        if (this.isCreditCheck) {
            if ((typeof this.customerStory.amount === 'undefined') || (this.customerStory.amount === '0') || (this.customerStory.amount === 0) || (this.customerStory.amount === '')) {
                if ((typeof this.totalPrice != 'undefined') || (this.totalPrice != '0') || (this.totalPrice != 0) || (this.totalPrice != '')) { 
                    this.customerStory.amount = this.totalPrice;
                }
            }
            if ((typeof this.customerStory.amount === 'undefined') || (this.customerStory.amount === '0') || (this.customerStory.amount === 0) || (this.customerStory.amount === '')) {
                const evt = new ShowToastEvent({
                    title:      CREDITAPP_SUBMITTEDERROR_TITLE,
                    message:    'Please provide an amount for your credit check.',
                    variant:    'error',
                    duration:   20000
                });
                this.dispatchEvent(evt);
                this.loading = false;
                return;
            }
            if ((typeof this.customerStory.location === 'undefined') || (this.customerStory.location === '')) {
                if ((typeof this.location != 'undefined') || (this.location != '')) {
                    this.customerStory.location = this.location;
                }
            }
            if ((typeof this.customerStory.location === 'undefined') || (this.customerStory.location === '')) {
                const evt = new ShowToastEvent({
                    title:      CREDITAPP_SUBMITTEDERROR_TITLE,
                    message:    'Please provide a location for your credit check.',
                    variant:    'error',
                    duration:   20000
                });
                this.dispatchEvent(evt);
                this.loading = false;
                return;
            }
        } else {
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
        }
        if(this.beneficialOwnerType != null){
            this.loading = false;
            if(this.beneficialOwner.length==0){
                // Immediate feedback
                const evt = new ShowToastEvent({
                    title:      CREDITAPP_UBO_TITLE,
                    message:    CREDITAPP_UBO_REQUIRED,
                    variant:    'error',
                    duration:   20000
                });
                this.dispatchEvent(evt);
                errorOccur=true;
            } else {
                for(var key in this.beneficialOwner) {
                    if(this.beneficialOwner[key].lastName === null || this.beneficialOwner[key].lastName === undefined || this.beneficialOwner[key].lastName === ''){
                        const evt = new ShowToastEvent({
                            title:      CREDITAPP_UBO_TITLE,
                            message:    CREDITAPP_UBO_LASTNAME,
                            variant:    'error',
                            duration:   20000
                            });
                        this.dispatchEvent(evt);
                        errorOccur=true;
                    } else if(this.beneficialOwner[key].firstName === null || this.beneficialOwner[key].firstName === undefined || this.beneficialOwner[key].firstName === ''){
                        const evt = new ShowToastEvent({
                            title:      CREDITAPP_UBO_TITLE,
                            message:    CREDITAPP_UBO_FIRSTNAME,
                            variant:    'error',
                            duration:   20000
                            });
                        this.dispatchEvent(evt);
                        errorOccur=true;
                    } else if(this.beneficialOwner[key].countryOfResidenceValue === null || this.beneficialOwner[key].countryOfResidenceValue === undefined || this.beneficialOwner[key].countryOfResidenceValue === ''){
                        const evt = new ShowToastEvent({
                            title:      CREDITAPP_UBO_TITLE,
                            message:    CREDITAPP_UBO_COUNTRY,
                            variant:    'error',
                            duration:   20000
                            });
                        this.dispatchEvent(evt);
                        errorOccur=true;
                    }
                }
            }
            
        }

        if(this.beneficialOwner.length != 0) {
            let areAnyDuplicates = false;

            this.beneficialOwner.map(function(obj) {
                return obj.firstName + obj.lastName + obj.middleName + obj.titleValue + obj.dateOfBirthValue;
            }).forEach(function (element, index, arr) {
                if (arr.indexOf(element) !== index) {
                    areAnyDuplicates = true;
                }
            });
    
            if(areAnyDuplicates == true){
                const evt = new ShowToastEvent({
                    title: 'Error',
                    message: 'Please enter a unique individual per Beneficial Owner Section',
                    variant: 'error',
                    duration: 20000
                })
                this.dispatchEvent(evt);
                errorOccur=true;
            }       
        }

        if(errorOccur==false){
            this.loading = true; 
            // Immediate feedback don't do this the customer will go insane
            /*const evt = new ShowToastEvent({
                title:      CREDITAPP_SAVING_TITLE,
                message:    CREDITAPP_SAVING_MESSAGE,
                variant:    'success',
                duration:   5000
            });
            this.dispatchEvent(evt);
            */
            this.loading = false;
            console.log('this.beneficialOwnerType on save:::'+this.beneficialOwnerType);
            var benifitOwnerRemoveBlank=[]
            for(var key in this.beneficialOwner) {
                if(this.beneficialOwner[key].lastName != null && this.beneficialOwner[key].lastName != undefined && this.beneficialOwner[key].lastName != '' 
                    && this.beneficialOwner[key].countryOfResidenceValue != null && this.beneficialOwner[key].countryOfResidenceValue != undefined && this.beneficialOwner[key].countryOfResidenceValue != '' 
                    && this.beneficialOwner[key].firstName != null && this.beneficialOwner[key].firstName != undefined && this.beneficialOwner[key].firstName != '') {
                        benifitOwnerRemoveBlank.push(this.beneficialOwner[key]);
                }
            }
            this.beneficialOwner=benifitOwnerRemoveBlank;
            this.loading=true;
            if (this.customerStory.customerStoryId) {
                console.log('Has customerStoryId: ' + this.customerStory.customerStoryId);
                if(typeof this.customerStory.amount != 'number') {
                    if (this.customerStory.amount.substring(0,1) == "$") {
                        this.customerStory.amount = this.removeInvalidPriceCharacters(this.customerStory.amount);
                    }    
                }
                UpdateQuoteData({
                    customerStory: this.customerStory,
                    ownershipInfo: this.beneficialOwnerType,
                    applicationNo: this.applicationNameValue,
                    applicationStatus: this.statusValue,
                    applicationDateSubmitted: this.creationDate
                }).then(result => {
                    if (result) {
                        UpdateBenefitOwnerData({
                            benefitOwner: this.beneficialOwner,
                            opportunityId: this.oppId
                        }).then(result => {
                            // Change the wire parameter to trigger a reload of the UBO wire
                            this.contactRolesReloaded += 1;
                            if (result) {
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
                                            message: CREDITAPP_SAVED_MESSAGE ,
                                            variant: 'success',
                                            duration: 10000,
                                        });
                                        this.dispatchEvent(evt);
                                         
                                        this.loading = false;
                                    } else {
                                        this.loading = false;
                                    }  
                                });
                            } else {
                                this.loading = false;
                            }
                        });
                    } else {
                        this.loading = false;
                    }
                });
            } else {
                this.beneficialOwnerSave = this.beneficialOwner;
                createNewOppForCreditCheck({'location' : this.customerStory.location, 'amount': this.customerStory.amount})
                    .then(result => {
                        console.log('createNewOpp finished');
                        this.customerStory.customerStoryId = result;
                        this.oppId = result;
                        UpdateQuoteData({
                            customerStory: this.customerStory,
                            ownershipInfo: this.beneficialOwnerType,
                            applicationNo: this.applicationNameValue,
                            applicationStatus: this.statusValue,
                            applicationDateSubmitted: this.creationDate
                        }).then(result => {
                            if (result) {
                                UpdateBenefitOwnerData({
                                    benefitOwner: this.beneficialOwnerSave,
                                    opportunityId: this.oppId
                                }).then(result => {
                                    // Change the wire parameter to trigger a reload of the UBO wire
                                    this.contactRolesReloaded += 1;
                                    if (result) {
                                        /* don't do this, the customer will go insane
                                        const evt = new ShowToastEvent({
                                            title: CREDITAPP_SAVED_TITLE,
                                            message: CREDITAPP_SAVED_MESSAGE + '1',
                                            variant: 'success',
                                            duration: 10000,
                                        });
                                        this.dispatchEvent(evt);
                                        */
                                        this.loading = false;
                                    } else {
                                        this.loading = false;
                                    }
                                });
                            } else {
                                this.loading = false;
                            }
                        });
                    });                
            }
            this.loading=false;
        }
        this.loading=false;
    }

     handleAppeal(){

        console.log('handle appeal' + this.oppId);

        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: window.location.origin + '/dllondemand/s/appeal?oppid=' + this.oppId
            }
        })        
    }

    /**
     * First validate and save the credit application in Salesforce
     * Then callSubmitCreditApp()
     */
    handleSaveAndSubmit() {

        console.log('customerInfoShow::'+this.customerInfoShow);
        this.loading = true;
        var errorOccur = false;

        // View in display form
        if(this.customerStory.acceptedCheckbox == false){
            // Immediate feedback
            const evt = new ShowToastEvent({
                title:      CREDITAPP_CUSTOMERAPPROVAL_TITLE,
                message:    CREDITAPP_CUSTOMERAPPROVAL_MESSAGE,
                variant:    'error',
                duration:   20000
            });
            this.dispatchEvent(evt);
            errorOccur=true;
             this.loading = false;
        } else if(this.customerInfoShow == false){
            // Immediate feedback
            const evt = new ShowToastEvent({
                title:      CREDITAPP_CUSTOMERINFO_TITLE,
                message:    CREDITAPP_CUSTOMERINFO_MESSAGE,
                variant:    'error',
                duration:   20000
            });
            this.dispatchEvent(evt);
            errorOccur=true;
        }else if(this.beneficialOwnerType != null){
            if(this.beneficialOwner.length == 0){
                // Immediate feedback
                const evt = new ShowToastEvent({
                    title:      CREDITAPP_UBO_TITLE,
                    message:    CREDITAPP_UBO_REQUIRED,
                    variant:    'error',
                    duration:   20000
                });
                this.dispatchEvent(evt);
                errorOccur=true;
            } else {
                for(var key in this.beneficialOwner) {
                    if(this.beneficialOwner[key].lastName === null || this.beneficialOwner[key].lastName === undefined || this.beneficialOwner[key].lastName === ''){
                        const evt = new ShowToastEvent({
                            title:      CREDITAPP_UBO_TITLE,
                            message:    CREDITAPP_UBO_LASTNAME,
                            variant:    'error',
                            duration:   20000
                            });
                        this.dispatchEvent(evt);
                        errorOccur=true;
                    } else if(this.beneficialOwner[key].firstName === null || this.beneficialOwner[key].firstName === undefined || this.beneficialOwner[key].firstName === ''){
                        const evt = new ShowToastEvent({
                            title:      CREDITAPP_UBO_TITLE,
                            message:    CREDITAPP_UBO_FIRSTNAME,
                            variant:    'error',
                            duration:   20000
                            });
                        this.dispatchEvent(evt);
                        errorOccur=true;
                    } else if(this.beneficialOwner[key].countryOfResidenceValue === null || this.beneficialOwner[key].countryOfResidenceValue === undefined || this.beneficialOwner[key].countryOfResidenceValue === ''){
                        const evt = new ShowToastEvent({
                            title:      CREDITAPP_UBO_TITLE,
                            message:    CREDITAPP_UBO_COUNTRY,
                            variant:    'error',
                            duration:   20000
                            });
                        this.dispatchEvent(evt);
                        errorOccur=true;
                    }
                }
            }
            
        }
        if (!this.isCreditCheck) {
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
        }
        if(errorOccur == false){
            this.loading=true;
            console.log('this.beneficialOwnerType:::'+this.beneficialOwnerType);
        
            var benifitOwnerRemoveBlank=[]
            for(var key in this.beneficialOwner) {
                if(this.beneficialOwner[key].lastName != null && this.beneficialOwner[key].lastName != undefined && this.beneficialOwner[key].lastName != '' 
                && this.beneficialOwner[key].countryOfResidenceValue != null && this.beneficialOwner[key].countryOfResidenceValue != undefined && this.beneficialOwner[key].countryOfResidenceValue != '' 
                && this.beneficialOwner[key].firstName != null && this.beneficialOwner[key].firstName != undefined && this.beneficialOwner[key].firstName != '') {
                    benifitOwnerRemoveBlank.push(this.beneficialOwner[key]);
                }
            }
            this.beneficialOwner=benifitOwnerRemoveBlank;

            UpdateQuoteData({customerStory:this.customerStory , ownershipInfo : this.beneficialOwnerType,applicationNo:this.applicationNameValue,applicationStatus:this.statusValue,applicationDateSubmitted:this.creationDate}).then(result =>{
                if(result){
                    console.log('this.beneficialOwner::test::'+JSON.stringify(this.beneficialOwner));
                
                    UpdateBenefitOwnerData({benefitOwner:this.beneficialOwner , opportunityId : this.oppId }).then(result =>{
                        if(result){

                            // Change the wire parameter to trigger a reload of the UBO wire
                            this.contactRolesReloaded +=1;

                            // Submit the credit app
                            //BUG-888445: When create a Credit Check without Quote this console log is throwing a error
                            //console.log('quoteid: ' + this.assets[0].quoteId);
                            if (this.isCreditCheck) {
                                 if (typeof this.totalPrice != 'undefined') {
                                    this.customerStory.amount = this.totalPrice;
                                }
                                if ((typeof this.customerStory.amount === 'undefined') || (this.customerStory.amount === '0') || (this.customerStory.amount === 0) || (this.customerStory.amount === '')) {
                                    const evt = new ShowToastEvent({
                                        title:      CREDITAPP_SUBMITTEDERROR_TITLE,
                                        message:    'Please provide an amount for your credit check.',
                                        variant:    'error',
                                        duration:   20000
                                    });
                                    this.dispatchEvent(evt);
                                    this.statusValue = this.submittedStatus;
                                    this.appEditMode = true;
                                    this.loading = false;
                                    return;
                                }
                                if (typeof this.location != 'undefined') {
                                    this.customerStory.location = this.location;
                                }
                                if ((typeof this.customerStory.location === 'undefined') || (this.customerStory.location === '')) {
                                    const evt = new ShowToastEvent({
                                        title:      CREDITAPP_SUBMITTEDERROR_TITLE,
                                        message:    'Please provide a location for your credit check.',
                                        variant:    'error',
                                        duration:   20000
                                    });
                                    this.dispatchEvent(evt);
                                    this.statusValue = this.submittedStatus;
                                    this.appEditMode = true;
                                    this.loading = false;
                                    return;
                                }
                                this.statusValue = this.submittedStatus;
                                this.appEditMode = true;
                                this.callPreQualSubmitCreditApp(this.oppId);                                
                            } else {
                                saveRelatedPartyForOpp({
                                    oppId: this.oppId, 
                                    firstName: this.personalGuar.firstName, 
                                    middleName: this.personalGuar.middleInitial, 
                                    lastName: this.personalGuar.lastName, 
                                    ssn: this.personalGuar.SocialSecurityNumber.split('-').join('')
                                }).then(result => {
                                    this.statusValue = this.submittedStatus;
                                    this.appEditMode = true;
                                    this.callSubmitCreditApp(this.assets[0].quoteId);
                                }).catch(error => {
                                    const evt = new ShowToastEvent({
                                        title:      CREDITAPP_SUBMITTEDERROR_TITLE,
                                        message:    'There was an error saving your personal guarantee',
                                        variant:    'error',
                                        duration:   20000
                                    });
                                    this.dispatchEvent(evt);
                                    this.statusValue = this.submittedStatus;
                                    this.appEditMode = true;
                                    this.loading = false;
                                });
                            }
                        } else {
                            console.log('handleOnSubmit 1');
                            this.loading = false;
                            this.statusValue = this.submittedStatus;
                            this.appEditMode = true;

                            // Immediate feedback
                            const evt = new ShowToastEvent({
                                title:      CREDITAPP_SUBMITTEDERROR_TITLE,
                                message:    CREDITAPP_SUBMITTEDERROR_MESSAGE,
                                variant:    'error',
                                duration:   20000
                            });
                            this.dispatchEvent(evt);
                        }
                    }).catch(error=>{
                        console.log('handleOnSubmit 2');
                        this.loading = false;
                        this.statusValue = this.submittedStatus;
                        this.appEditMode = true;

                        // Immediate feedback
                        const evt = new ShowToastEvent({
                            title:      CREDITAPP_SUBMITTEDERROR_TITLE,
                            message:    CREDITAPP_SUBMITTEDERROR_MESSAGE,
                            variant:    'error',
                            duration:   20000
                        });
                        this.dispatchEvent(evt);
                    });
                } else {
                    console.log('handleOnSubmit 3');
                    this.loading=false;
                    this.statusValue=this.submittedStatus;
                    this.appEditMode = true;

                    // Immediate feedback
                    const evt = new ShowToastEvent({
                        title:      CREDITAPP_SUBMITTEDERROR_TITLE,
                        message:    CREDITAPP_SUBMITTEDERROR_MESSAGE,
                        variant:    'error',
                        duration:   20000
                    });
                    this.dispatchEvent(evt);
                }
            }).catch(error=>{
                console.log('handleOnSubmit 4');
                this.loading=false;
                this.statusValue=this.submittedStatus;
                this.appEditMode = true;

                // Immediate feedback
                const evt = new ShowToastEvent({
                    title:      CREDITAPP_SUBMITTEDERROR_TITLE,
                    message:    CREDITAPP_SUBMITTEDERROR_MESSAGE,
                    variant:    'error',
                    duration:   20000
                });
                this.dispatchEvent(evt);
            });
        }
    }

    callPreQualSubmitCreditApp(prequalOpportunityId) {
        console.log('callPreQualSubmitCreditApp: ' + prequalOpportunityId);
         
        submitPreQualCreditApp({'opportunityId' : prequalOpportunityId})
            .then(result => {
                if(result) {
                    console.log('submitCreditApp: ' + result);

                    // CreditAppUtils returns a response code 200 if it successfully receives the call.
                    if(result == 'OK'){
                        this.isLoadedQuote = true;
                         
                        this.initializeCometD(this.channel,this.oppId);

                         

                    } else{
                        this.loading = false;
                        this.statusValue = this.submittedStatus;
                        this.appEditMode = true;

                        const evt = new ShowToastEvent({
                            title: CREDITAPP_SUBMITTEDERROR_TITLE,
                            message: CREDITAPP_SUBMITTEDERROR_MESSAGE,
                            variant: 'error',
                            duration: 10000
                        });
                        this.dispatchEvent(evt);
                    }
                } else {
                    console.log('handleOnSubmitPrequal 5');
                    this.loading = false;
                    this.statusValue = this.submittedStatus;
                    this.appEditMode = true;

                    // Immediate feedback
                    const evt = new ShowToastEvent({
                        title:      CREDITAPP_SUBMITTEDERROR_TITLE,
                        message:    CREDITAPP_SUBMITTEDERROR_MESSAGE,
                        variant:    'error',
                        duration:   20000
                    });
                    this.dispatchEvent(evt);
                }
            }).catch(error => {
            let errorResult = JSON.parse(result);
            console.log('errorResult.error.status'+errorResult.error.status);

            if(errorResult.error.status == 404){
                // Immediate feedback
                const evt = new ShowToastEvent({
                    title:      CREDITAPP_SUBMITTEDERROR_TITLE,
                    message:    CREDITAPP_SUBMITTEDERROR_404,
                    variant:    'error',
                    duration:   20000
                });
                this.dispatchEvent(evt);
            } else if(errorResult.error.status == 400 || errorResult.error.status == 500){
                console.log('handleOnSubmitPrequal 6');

                // Immediate feedback
                const evt = new ShowToastEvent({
                    title:      CREDITAPP_SUBMITTEDERROR_TITLE,
                    message:    CREDITAPP_SUBMITTEDERROR_400_500,
                    variant:    'error',
                    duration:   20000
                });
                this.dispatchEvent(evt);
            } else {
                console.log('handleOnSubmitPrequal 7');

                // Immediate feedback
                const evt = new ShowToastEvent({
                    title:      CREDITAPP_SUBMITTEDERROR_TITLE,
                    message:    CREDITAPP_SUBMITTEDERROR_GENERAL,
                    variant:    'error',
                    duration:   20000
                });
                this.dispatchEvent(evt);
            }
            console.log('error pre qual submit credit app ::'+JSON.stringify(error));
        });
    }

    /*
    * Perform the integrated callout and handle the response.
    * */
    callSubmitCreditApp(quoteId){
        console.log('callSubmitCreditApp: ' + quoteId);
        
        submitCreditApp({'quoteId': quoteId}).then(result =>{
            if(result) {
                console.log('submitCreditApp: ' + result);

                // CreditAppUtils returns a response code 200 if it successfully receives the call.
                if(result == 'OK'){
                    this.isLoadedQuote = true;
                    
                    this.initializeCometD(this.channel,this.oppId);
                     
                 

                } else{
                    this.loading = false;
                    this.statusValue = this.submittedStatus;
                    this.appEditMode = true;

                    const evt = new ShowToastEvent({
                        title: CREDITAPP_SUBMITTEDERROR_TITLE,
                        message: CREDITAPP_SUBMITTEDERROR_MESSAGE,
                        variant: 'error',
                        duration: 10000
                    });
                    this.dispatchEvent(evt);
                }
            } else {
                console.log('handleOnSubmit 5');
                this.loading = false;
                this.statusValue = this.submittedStatus;
                this.appEditMode = true;

                // Immediate feedback
                const evt = new ShowToastEvent({
                    title:      CREDITAPP_SUBMITTEDERROR_TITLE,
                    message:    CREDITAPP_SUBMITTEDERROR_MESSAGE,
                    variant:    'error',
                    duration:   20000
                });
                this.dispatchEvent(evt);
            }
        }).catch(error=>{
            let errorResult = JSON.parse(result);
            console.log('errorResult.error.status'+errorResult.error.status);

            if(errorResult.error.status == 404){
                // Immediate feedback
                const evt = new ShowToastEvent({
                    title:      CREDITAPP_SUBMITTEDERROR_TITLE,
                    message:    CREDITAPP_SUBMITTEDERROR_404,
                    variant:    'error',
                    duration:   20000
                });
                this.dispatchEvent(evt);
            } else if(errorResult.error.status == 400 || errorResult.error.status == 500){
                console.log('handleOnSubmit 6');

                // Immediate feedback
                const evt = new ShowToastEvent({
                    title:      CREDITAPP_SUBMITTEDERROR_TITLE,
                    message:    CREDITAPP_SUBMITTEDERROR_400_500,
                    variant:    'error',
                    duration:   20000
                });
                this.dispatchEvent(evt);
            } else {
                console.log('handleOnSubmit 7');

                // Immediate feedback
                const evt = new ShowToastEvent({
                    title:      CREDITAPP_SUBMITTEDERROR_TITLE,
                    message:    CREDITAPP_SUBMITTEDERROR_GENERAL,
                    variant:    'error',
                    duration:   20000
                });
                this.dispatchEvent(evt);
            }
            console.log('error submit credit app ::'+JSON.stringify(error));
        });
    }

    
    

    // -------------------model pop-up on click of Submit Credit Application button---------------------//
    /**
     * To check whether the customer approval check box is checked/unchecked.
     * @Param Holla {*} event
     */
    onClickOfCheckBox(event){
        if(event.target.checked){
            this.customerStory.acceptedCheckbox = true;
        } else{
            this.customerStory.acceptedCheckbox = false;
        }
    }


    //onchange function
    handleDependentTermsPicklistChange(event){
        this.rateType=event.detail.value;
    }
    handleFinanceTermChange(event){
        this.financeTerm=event.detail.value;
    }
    handleDependentRatesPicklistChange(event){
        this.financeType=event.detail.value;
    }
    handlePaymentFreqChange(event){
        this.paymentFrequency=event.detail.value;
    }
    handleAdvancePaymentChange(event){
        this.advPayments=event.detail.value;
    }
    handlebusinessStructureChange(event){
        this.customerStory.businessStructure = event.detail.value;
    }
    handleStoryChange(event){
        this.customerStory.story=event.detail.value;
    }
    handleyearsInBusinessChange(event){
        this.customerStory.yearsInBusiness=event.detail.value;
    }
    handleMakePicklistChange(event){
        for(var i=0;i<this.assets.length;i++) {
            if(this.assets[i].assetNo==event.target.name) {
                this.assets[i].makeValue=event.detail.value;
            }
        }
    }
    handleAssetTypeChange(event){
        for(var i=0;i<this.assets.length;i++) {
            if(this.assets[i].assetNo==event.target.name) {
                this.assets[i].assetTypeValue=event.detail.value;
            }
        }
    }
    handleModelPicklistChange(event){
        for(var i=0;i<this.assets.length;i++) {
            if(this.assets[i].assetNo==event.target.name) {
                this.assets[i].modelValue=event.detail.value;
            }
        }
    }
    handleMastTypeChange(event){
        for(var i=0;i<this.assets.length;i++) {
            if(this.assets[i].assetNo==event.target.name) {
                this.assets[i].mastTypeValue=event.detail.value;
            }
        }
    }
    handleAssetOperatingChange(event){
        for(var i=0;i<this.assets.length;i++) {
            if(this.assets[i].assetNo==event.target.name) {
                this.assets[i].assetOperatingEnvironmentValue=event.detail.value;
            }
        }
    }
    handleAnnualHoursChange(event){
        for(var i=0;i<this.assets.length;i++) {
            if(this.assets[i].assetNo==event.target.name) {
                this.assets[i].annualHoursValue=event.detail.value;
            }
        }
    }
    handlenumberOfUnitsChange(event){
        for(var i=0;i<this.assets.length;i++) {
            if(this.assets[i].assetNo==event.target.name) {
                this.assets[i].numberOfUnitsValue=event.detail.value;
            }
        }
    }
    handleUnitSalesPriceChange(event){
        for(var i=0;i<this.assets.length;i++) {
            if(this.assets[i].assetNo==event.target.name) {
                this.assets[i].unitSalesPriceValue=event.detail.value;
                 
            }
        }
    }

    handlerelatedAssetPicklistChange(event){
        for(var i=0;i<this.accessories.length;i++) {
            if(this.accessories[i].accessoryNo==event.target.name) {
                this.accessories[i].relatedAssetValue=event.detail.value;
            }
        }
    }
    handleAccessoryChange(event){
        for(var i=0;i<this.accessories.length;i++) {
            if(this.accessories[i].accessoryNo==event.target.name) {
                this.accessories[i].accessoryValue=event.detail.value;
            }
        }
    }
    handleUnitSalesPricePicklistChange(event){
        for(var i=0;i<this.accessories.length;i++) {
            if(this.accessories[i].accessoryNo==event.target.name) {
                this.accessories[i].unitSalesPriceValue=event.detail.value;
            }
        }
    }
    handleNumberofUnitsChange(event){
        for(var i=0;i<this.accessories.length;i++) {
            if(this.accessories[i].accessoryNo==event.target.name) {
                this.accessories[i].numberofUnitsValue=event.detail.value;
            }
        }
    }

    handlePersonalFirstNameChange(event){
        for(var i=0;i<this.beneficialOwner.length;i++) {
            if(this.beneficialOwner[i].ownerNo==event.target.name) {
                this.beneficialOwner[i].firstName=event.detail.value;
            }
        }
    }

    handleMiddleNameChange(event){
        for(var i=0;i<this.beneficialOwner.length;i++) {
            if(this.beneficialOwner[i].ownerNo==event.target.name) {
                this.beneficialOwner[i].middleName=event.detail.value;
            }
        }
    }

    handleLastNameChange(event){
        for(var i=0;i<this.beneficialOwner.length;i++) {
            if(this.beneficialOwner[i].ownerNo==event.target.name) {
                this.beneficialOwner[i].lastName=event.detail.value;
            }
        }
    }

    handleTitlePicklistChange(event){
        for(var i=0;i<this.beneficialOwner.length;i++) {
            if(this.beneficialOwner[i].ownerNo==event.target.name) {
                this.beneficialOwner[i].titleValue=event.detail.value;
            }
        }
    }

    handledateOfBirthChange(event){
        for(var i=0;i<this.beneficialOwner.length;i++) {
            if(this.beneficialOwner[i].ownerNo == event.target.name) {
                this.beneficialOwner[i].dateOfBirthValue = event.detail.value;
                this.beneficialOwner[i].dateOfBirthValueForMasking = event.detail.value;
            }
        }
    }

    handlecountryOfResidencePicklistChange(event){
        for(var i=0;i<this.beneficialOwner.length;i++) {
            if(this.beneficialOwner[i].ownerNo==event.target.name) {
                this.beneficialOwner[i].countryOfResidenceValue=event.detail.value;
            }
        }
    }
    handleownershipPercentageChange(event){
        for(var i=0;i<this.beneficialOwner.length;i++) {
            if(this.beneficialOwner[i].ownerNo==event.target.name) {
                this.beneficialOwner[i].ownershipPercentageValue=event.detail.value;
            }
        }
    }

    // Tag along with the customer story.
    beneficialOwnerChange(event){
        console.log('event.detail.value::'+event.target.value);
        console.log('console.log::'+this.template.querySelector(`[data-id="Owner"]`).checked);
        if(event.target.name!="Owner"){
            this.template.querySelector(`[data-id="Owner"]`).checked=false;
        }
        if(event.target.name!="Individual"){
            this.template.querySelector(`[data-id="Individual"]`).checked=false;
        }
        if(event.target.name!="boardofDirectors"){
            this.template.querySelector(`[data-id="boardofDirectors"]`).checked=false;
        }

        if(event.target.checked==true) {
            this.customerStory.beneficialOwnerType = event.target.value;
            this.beneficialOwnerType=event.target.value;
        } else {
            this.customerStory.beneficialOwnerType = null;
            this.beneficialOwnerType=null;
        }
        
        console.log('this.customerStory.beneficialOwnerType ::'+this.customerStory.beneficialOwnerType );
        console.log('this.beneficialOwnerType ::'+this.beneficialOwnerType );
        

     
    }

    pageReference;

    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        if (currentPageReference) {
            this.pageReference = {};
            this.pageReference.attributes = {};
            this.pageReference.attributes.recordId = this.oppId;
            this.pageReference.attributes.actionName = 'view';
            this.pageReference.type = 'standard__recordPage';
            if(typeof this.oppId === 'undefined'){
                this.statusValue = 'Application Draft';
                this.totalPrice = 0;
            }
            console.log('page reference');
            console.log(JSON.parse(JSON.stringify(this.pageReference)));
            //this.setCurrentPageIdBasedOnUrl();
        }
    }

    /*get newPageReference() {
        return Object.assign({}, this.pageReference, {
            state: Object.assign({}, this.pageReference.state, this.newPageReferenceUrlParams)
        });
    }

    get newPageReferenceUrlParams() {
        return {
            oppId: this.oppId
        };
    }

    setCurrentPageIdBasedOnUrl() {
        this.newPageId = this.pageReference.state.oppId;
    }*/

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

    handleCustomerInfoShow(event) {
        this.customerInfoShow=event.detail;

    }

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

    // Handle enroll in financing
     handleOnEnrolment(){
        console.log('Handle Enrolment process on Credit application page !!');
        this.loading = true;
        if(this.oppId != null && this.oppId != undefined && this.oppId != ''){
            this.loading = false;
            this[NavigationMixin.Navigate]({type: 'standard__webPage',attributes: {
                url: window.location.origin + '/dllondemand/s/enroll-screen?oppId=' + this.oppId
                }
            })
        }
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'dismissible'
        });
        this.dispatchEvent(event);
    }


    @wire(getSessionId)
    wiredSessionId({ error, data }) {
        if (data) {
            this.sessionId = data;
            this.error = undefined;
            loadScript(this, cometd)
            .then(() => {
                console.log('initializing');
                // dont' call here;  too early;  this.initializeCometD(this.channel,this.oppId);
            });
        } else if (error) {
            this.error = error;
            this.sessionId = undefined;
            console.log('error is: ' + JSON.stringify(this.error));
        }
    }

    // initialize CometD 
    initializeCometD(channel,oppId) {
         
        if (this.libInitialized) {
            return;
        }
        this.libInitialized = true;
        var lwcThisContext = this;
        var cometdlib = new window.org.cometd.CometD();
        cometdlib.configure({
            url: window.location.protocol + '//' + window.location.hostname + '/cometd/56.0/',
            requestHeaders: { Authorization: 'OAuth ' + this.sessionId},
            appendMessageTypeToURL : false,
            logLevel: 'debug'
        });
        cometdlib.websocketEnabled = false;
        cometdlib.handshake(function(status) {
            if (status.successful) {
                cometdlib.subscribe(channel, function(message){
                    lwcThisContext.handlePlatformEvent(message);
                });
                
            } else {
                console.error('Error in handshaking: ' + JSON.stringify(status));
            }
        });
    }

    handlePlatformEvent(message){
        console.log('in process event' + JSON.stringify(message));

        if (message.data.payload.Opportunity__c == this.oppId){

            if (message.data.payload.Succeeded__c == true){
                const event = new ShowToastEvent({
                    title: 'Success',
                    message: 'Application Submitted Successfully!',
                    variant: 'success',
                    mode: 'sticky'
                });
                this.dispatchEvent(event);
            }
            else{
                const event = new ShowToastEvent({
                    title: 'Error',
                    message: 'Application Submit Failed! - contact support - ' + message.data.payload.Error_Message__c ,
                    variant: 'error',
                    mode: 'sticky'
                });
                this.dispatchEvent(event);
            }

            this.opportunityDataReloaded += 1;
            this.loading = false;
            this.appEditMode = false;


        }
    }

        
    

    
    
    

}