/**
 * Created by ShiqiSun on 11/17/2021.  then tod could not add one more comment in 1 year.
*
*  Change Log:
*  07/22/2022 - MRM - made leasetype picklist dynamic based on asset condition.
*  11/17/2022 - MRM - made pricing a reusable component to suppor appeals; Pricing 2.0
                MRM - removed call pricing and save for all options. only save the option changed;
                      this saves tons of processing and was not required
                    -  
                
*
*/

import {api, track, LightningElement, wire} from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
 

//pricing stuff
import getPrograms from "@salesforce/apex/PricingUtils.getPrograms";
import getFinancialProducts from "@salesforce/apex/PricingUtils.getFinancialProducts";
import getFinancialProduct from "@salesforce/apex/PricingUtils.getFinancialProduct";
import getPrice from "@salesforce/apex/PricingUtils.getPrice";
import getSalesReps from "@salesforce/apex/PricingUtils.getSalesReps";
 
//data manipulation
import createQuoteOpportunity from "@salesforce/apex/CreateQuoteOpportunity.CreateQuoteOpportunity";
import cloneQuoteOption from "@salesforce/apex/CreateQuoteOpportunity.CloneQuoteOption";
import editQuoteOption from "@salesforce/apex/CreateQuoteOpportunity.EditQuoteOption";
import saveQuotePricingDataBackToServer from "@salesforce/apex/CreateQuoteOpportunity.saveQuotePricingDataBackToServer";
import saveQuoteLinePricingDataBackToServer from "@salesforce/apex/CreateQuoteOpportunity.saveQuoteLinePricingDataBackToServer";
import queryQuoteOpportunity from "@salesforce/apex/CreateQuoteOpportunity.QueryQuoteOpportunity";

import CREDITAPP_ASSET_TITLE from '@salesforce/label/c.CREDITAPP_ASSET_TITLE';
import CREDITAPP_ASSET_DUP from '@salesforce/label/c.CREDITAPP_ASSET_DUP';


const SEARCH_DELAY = 300;

export default class PricingComponent extends NavigationMixin(LightningElement) {

    // these are used to create pricing component
    @api sectionTitle;
    @api sectionSubTitle;
    @api oppid;
    @api option;
    @api newoption;
    @api program;
    @api clone;

    createdQuote = false;

    error;
    accordianSection = '';
    triggerParentSave = false;

    //Object model
    assets = [{
        sectionName: 'asset0',
        assetHeading: 'Asset 1',
        assetNo: 0,
        isFirst: true
    }];
    accessories = [{
        accNo: 0,
        accessoryHeading: 'Accessory 1',
        isFirst: true
    }];
    relatedAssets = [];
    options = [];
    opportunityId;
   

    @track quoteObject = {
        deleteAssets: [],
        isEdit: null,
        isClone: null,
        assetTypeQuote: 'New',
        financeType:'BO',
        paymentFrequency: 'Monthly',
        advPayments: '0',
        program: null,
        programId: null,
        location: null,
        locationId: null,
        nickname: null,
        financeTerm: null,
        option: null
    };


    quoteObjectSummary = [];

    //trackers
    @track currentPosition = 0;
    @track currentAccPosition = 0;
    @track loading = false;
    @track hasQuotes = false;
    @track specificationTabActive = true;
    @track currentTab = 'proposal';
    @track optionsPicklistVal = 0;

    //Values to be used by input fields
    nickname = '';
    location;
    salesRep;
    assetTypeQuote = 'New';
    userSite;
    quoteNumber;

    //finance attributes
    rateType;
    financeTerm;
        financeType = 'BO';
    paymentFrequency = 'Monthly';
    advPayments = '0';

    openAccordionSections = [];

    //picklists
    siteList = [];
    programPicklist = [];
    salesRepList = [];
    assetTypeListQuote = [
        {label: 'New Asset', value: 'New'},
        {label: 'Used Asset', value: 'Used'}
    ];
    rateTypePicklist = [/*{value:'Promo', label:'Promo'}*/];
    financeTermPicklist = [/*
        {value: '24', label: '24'},
        {value: '36', label: '36'},
        {value: '48', label: '48'}*/
    ];
    financeTypePicklist = [];
    //{value: 'FPPO', label: 'FPPO'}

    frequencyPicklist = [
        {value: 'Monthly', label: 'Monthly'},
        {value: 'Quarterly', label: 'Quarterly'},
        {value: 'semi-annually', label: 'Semi-Annually'},
        {value: 'annually', label: 'Annually'}
    ];
    advancedPaymentsPicklist = [
        {value: '0', label: '0'},
        {value: '1', label: '1'},
        {value: '2', label: '2'},
        {value: '3', label: '3'}
    ];

    optionsPicklist = [];
    osidForSalesReps = [];
    showCreateInstead = false;

    //Search
    newContactRecord;
    comments;
    displayLocation;
    displayProgram;
    salesRepDisplayName;
    creditAppId;
    hasNoActiveQuoteForCredApp = true;
    displayModal = false;
    displayModalDelete = false;
    currentDeleteId = '';
    hasLocationSelection = true;
    hasLocationSelectionSalesRep = true;
    leaseTypeSummary = '-';
    rateTypeSummary = '-';
    advancedPaymentsSummary = '-';
    baseUnitSalesPriceWithoutDuplicatesSummary = '-';
    baseUnitSalesPriceSummary = '-';
    totalPaymentSummary = '-'; 
    residualSummary = '-';
    interestRateSummary = '-';
    termSummary = '-';
    activeOption;
    displayNameForLocation;
    displayNameForLocationPicklist;
    onlyValidateHeader = false;
    proposalIdsIncluded = [];
    doRedirectToCreditApp = false;
    currentPageReference;
    pricingApiCallCount = 0;
    customerComments = '';
    doAssetDeleteInstead = false;
    deleteAssetEventSavedForModal;
    doAccessoryDeleteInstead = false;
    deleteAccessoryEventSavedForModal;
    isLoadedQuote = false;
    salesRepInputValue = '';
    refreshSalesRepDropdown = true;
    saveRunning = false;

    /***************************************************************************************************************
     * api section - communication from parent
     * 
     * 3 key apis - childOption, childCondition, childPricing
     * 
     * these three are called by parent to set up the overall paramerters for pricing to execute; for example
     * program, location, new/used, nick name, sales rep
    ***************************************************************************************************************/
    

    /***************************************************************************************************************
     * isRateDisabled
     ***************************************************************************************************************/
    @api
    get isRateDisabled() {

        let result =  (this.program === '') || (this.assetTypeQuote === '') || (this.location === '') || (this.nickname === '');
        if (!result && (this.openAccordionSections.length === 0)) {
            this.openAccordionSections = ['Finance Structure'];
        }
        else if (result && this.openAccordionSections.includes('Finance Structure') && (this.openAccordionSections.length === 1)) {
            this.openAccordionSections = [];
        }
        
        return result;
    }

    
    /***************************************************************************************************************
     * isFinanceTermDisabled
    ***************************************************************************************************************/
    
    @api
    get isFinanceTermDisabled() {
        return (typeof this.rateType === 'undefined') || (this.program === '') || (this.assetTypeQuote === '') || (this.location === '') || (this.nickname === '');
    }
    /***************************************************************************************************************
    * childCondition - parent calls this to signal new/used changed
    ***************************************************************************************************************/
    @api childCondition(option){

        this.assetTypeQuote = option;
        this.quoteObject.assetTypeQuote  = option;
        
        let wrapperEvent2 = {value: option};
        let wrapperEvent = {target: wrapperEvent2};
        this.handleChange(wrapperEvent);
        
    }
    /***************************************************************************************************************
     * childOption - parent calls this to signal option change on quot
     * 
     * 
     * 
     ***************************************************************************************************************/
    @api childOption(option){
        //console.log('called child option: ' +  option);
       
        let wrapperEvent2 = {value: option};
        let wrapperEvent = {target: wrapperEvent2, skipLoadToFalse: false};
        this.handleOptionPicklist(wrapperEvent);
    }
    /***************************************************************************************************************
     * childPricing - parent calls this to send in the nickname sales rep location and program
     * 
     * 
     ***************************************************************************************************************/
    @api childPricing(quoteObject){

        //console.log('**** in child pricing *****'  );
 
        this.quoteObject = quoteObject;

        this.assetTypeQuote = this.quoteObject.assetTypeQuote;
        this.programId = this.quoteObject.programId;
        this.program = this.quoteObject.programId;
        this.location = this.quoteObject.location;
        this.nickname = this.quoteObject.nickname;

        this.accordianSection = 'Finance Structure'; 
        this.handleDependentRatesPicklistChange(this.quoteObject.programId);

    }

    /***************************************************************************************************************
     *  
     ***************************************************************************************************************/
    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        if (currentPageReference) {
            this.currentPageReference = currentPageReference;
            this.setCurrentPageIdBasedOnUrl();
        }
    }

    /***************************************************************************************************************
     *  
     ***************************************************************************************************************/
    get newPageReference() {
        return Object.assign({}, this.currentPageReference, {
            state: Object.assign({}, this.currentPageReference.state, this.newPageReferenceUrlParams)
        });
    }

    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
    get newPageReferenceUrlParams() {
        return {
            oppid: this.opportunityId
        };
    }

    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
    setCurrentPageIdBasedOnUrl() {
        this.newPageId = this.currentPageReference.state.oppid;
    }

    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
    connectedCallback() {
        
        //console.log('this opp id is ' + this.oppid);
        if (this.oppid) {
            this.loading = true;
            this.isLoadedQuote = true;
            
            queryQuoteOpportunity({'oppId' : this.oppid})
                .then(result => {
                 
                    this.parseData(result);
                 
                    this.addPricingDataToLoadedQuotes();
                     
                     
                    if (this.options.length !== 0) {
                        this.hasQuotes = true;
                        this.accordianSection = 'Finance Structure'; 
                        this.hasLocationSelection = true;
                        this.hasLocationSelectionSalesRep = false;
                        this.specificationTabActive = true;  ///mrm change 1
                        this.program = this.options[0].quote.Program_ID__c;
                        

                        if (this.newoption == 'New Option'){
                            let wrapperEvent2 = {value: this.newoption};
                            let wrapperEvent = {target: wrapperEvent2, skipLoadToFalse: false};
                            this.handleOptionPicklist(wrapperEvent);
                            this.optionsPicklistVal = this.newoption;
                            this.loading = false;

                        }
                        else{
                            if (this.optionsPicklist.length > 1) {
                                if (typeof this.newoption === 'undefined')
                                    this.newoption = 0;
                                let wrapperEvent2 = {value: this.newoption};
                                let wrapperEvent = {target: wrapperEvent2, skipLoadToFalse: true};
                                this.handleOptionPicklist(wrapperEvent);
                                this.quoteObject.option = this.newoption;
                                this.optionsPicklistVal = this.newoption;
                            }
                        }
                        this.nickname = result.newOpp.Nickname__c;
                        if (result.newOpp.Comments__c) {
                            this.customerComments = result.newOpp.Comments__c;
                        }
                        this.opportunityId = result.newOpp.Id;
                        this.displayProgram = this.options[0].quote.Program__c;
                        this.assetTypeQuote = this.options[0].quote.Asset_Type__c;
                        if (this.options[0].quote.Partner_Sales_Rep__r) {
                            this.salesRepDisplayName = this.options[0].quote.Partner_Sales_Rep__r.Name;
                            this.salesRep = this.options[0].quote.Partner_Sales_Rep__r.Name; 
                        }
                        this.location = this.options[0].quote.Location_ID__c;
                        this.displayLocation = result.newOpp.Account.Name;
                        for (let i = 0; i < this.options.length; i++) {
                            if (this.options[i].quote.Is_Primary__c) {
                                this.creditAppId = this.options[i].quote.Id;
                                break;
                            }
                        }
                        if (!this.creditAppId) {
                            this.creditAppId = this.options[0].quote.Id;
                        }
                        let loadsToGo = 2;
                             
                        if (this.location) {
                            getPrograms({siteName: this.location})
                                .then(result => {
                                    let plist = [];
                                    let data = JSON.parse(result);
                                    data.forEach(function (element) {
                                        ////console.log(element.programName + ' ' + element.programId);
                                        plist.push({label: element.programName, value: element.programId});

                                    });
                                    this.programPicklist = plist;
                                    setTimeout(() => {
                                        loadsToGo--;
                                        if (loadsToGo === 0) {
                                            this.loading = false;
                                        }
                                    }, 1500);
                                })
                                .catch(error => {
                                    this.showToast('Something went wrong', error.body.message, 'error');
                                    loadsToGo--;
                                    if (loadsToGo === 0) {
                                        this.loading = false;
                                    }
                                    this.programPicklist = undefined;
                                    return;
                                });
                                
                            getSalesReps({ originatingSiteId: this.location })
                                .then(result => {

                                    let data = JSON.parse(result);
                                    let sList = [];

                                    data.forEach(function(element){

                                        sList.push({label: element.name, value: element.id});

                                    });

                                    sList.push({label: 'None', value: ''});

                                    this.salesRepList = sList;
                                    loadsToGo--;
                                    if (loadsToGo === 0) {
                                        this.loading = false;
                                    }
                                })
                                .catch(error => {
                                    loadsToGo--;
                                    if (loadsToGo === 0) {
                                        this.loading = false;
                                    }
                                    this.showToast('Something went wrong', error.body.message, 'error');
                                });
                             
                            if (this.financeType) {
                                loadsToGo++;
                                this.quoteObject.program = this.program;
                                this.quoteObject.programId = this.program;
                                
                                getFinancialProducts({programId: this.program, financetype: this.financeType, newused: this.assetTypeQuote})
                                    .then(result => {
                                        let plist = [];
                                        let tempData = JSON.parse(result);
                                        let onlyoneid = null;
                                        let onlyonelabel = null;
                                        if (tempData.length > 0) {
                                            tempData.forEach(function (element) {
                                                plist.push({label: element.name, value: element.id});
                                                onlyoneid = element.id;
                                                onlyonelabel = element.name;
                                            });

                                            if (tempData.length == 1) {
                                                this.financialproduct = onlyoneid;
                                                this.rateType = onlyoneid;
                                                this.quoteObject.rateType = onlyonelabel;
                                                this.quoteObject.rateTypeId = onlyoneid;
                                                this.rateTypePicklist = plist;
                                                this.loadTerms();
                                                return;
                                            }
                                        }
                                        loadsToGo--;
                                        if (loadsToGo === 0) {
                                            this.loading = false;
                                        }
                                        this.rateTypePicklist = plist;
                                    })
                                    .catch(error => {
                                        //console.log(JSON.stringify(error));
                                    });
                                    
                            }
                        }
                    }
                    this.loading = false;
                }).catch(error => {
                    this.showToast('Invalid Opportunity Id', this.oppid, 'error');
                    this.loading = false;
            });
        }
        /**
         * This callback is called before navigating to the new record form
         * @param selectedNewRecordOption the new record option that was selected
         * @return Promise - once resolved, the user is taken to the new record form
         */
        const preNavigateCallback = (selectedNewRecordOption) => {
            return new Promise((resolve) => {
                // TODO: add some preprocessing (i.e.: save the current form state)

                // Always resolve the promise otherwise the new record form won't show up
                resolve();
            });
        };

        // Assign new record options with the pre-navigate callback to your lookup
        this.newContactRecord = [
            {value: 'Contact', label: 'New Contact', preNavigateCallback},

        ];

        //console.log('end of callback');
        
    }
    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
    
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'dismissible'
        });
        this.dispatchEvent(event);
    }
    
    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
    
    //Functions for loading in dependent picklist values
    loadRates() {

        //this.loading = true;

        console.log('loading rates: ' + this.assetTypeQuote);

        getFinancialProducts({programId: this.program, financetype: this.financeType, newused: this.assetTypeQuote})
            .then(result => {
                let plist = [];
                let tempData = JSON.parse(result);
             
                let onlyoneid = null;
                let onlyonelabel = null;
                if (tempData.length > 0) {
                    tempData.forEach(function (element) {
                        plist.push({label: element.name, value: element.id});
                        onlyoneid = element.id;
                        onlyonelabel = element.name;
                    });

                    if (tempData.length == 1) {
                        this.financialproduct = onlyoneid;
                        this.rateType = onlyoneid;
                        this.quoteObject.rateType = onlyonelabel;
                        this.quoteObject.rateTypeId = onlyoneid;
                        this.loadTerms();
                        this.rateTypePicklist = plist;
                        return;
                    }

                }
                this.rateTypePicklist = plist;
                
            })
            .catch(error => {
                //console.log('error' + error);
                this.showToast('Something went wrong', error.body.message, 'error');
                this.loading = false;
                this.rateTypePicklist = undefined;
            });

            
    }

    
    
    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
    loadTerms() {

        ////console.log('in load terms in pircing component' + this.program);

        getFinancialProduct({programId: this.program, productId: this.rateType, newused: this.assetTypeQuote})
            .then(result => {
             
                let tList = [];


                let obj = JSON.parse(result);
             
                let purchaseOptions = obj.data.purchaseOptions;
                 

                /*
                financeTypePicklist = [
                    {value: 'FMV', label: 'Fair Market Value ( FMV )'},
                    {value: 'BO', label: '$1 Buy out'}
                ];
                */
                
                this.financeTypePicklist = [];
              
                for (let j = 0; j < purchaseOptions.length; j++){
                    if (purchaseOptions[j] === 'fair-market-value'){
                        this.financeTypePicklist.push({label: 'Fair Market Value ( FMV )', value: 'FMV'});
                    }
                    if (purchaseOptions[j] === 'dollar-out'){
                        this.financeTypePicklist.push({label: '$1 Buy out', value: 'BO'});
                    }
                }
                

                let monthArray = obj.data.duration.numberOfmonths;
                let inputs = monthArray.values[0];
                let minimum = inputs.minimum;
                let maximum = inputs.maximum;

                for (let i = minimum; i < maximum + 1; i++) {
                    if ((i % 12) === 0) {
                        tList.push({label: i.toString(), value: i.toString()});
                    }
                }

                for (let i = minimum; i < maximum + 1; i++) {
                    if ((i % 12) !== 0) {
                        tList.push({label: i.toString(), value: i.toString()});
                    }
                }

                this.financeTermPicklist = tList;

                if(this.pricingApiCallCount === 0) {
                    this.loading = false;
                }
            })
            .catch(error => {
                this.showToast('Something went wrong', error.body.message, 'error');
                this.loading = false;
                this.rateTypePicklist = undefined;
            });
    }

    
    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
    //update picklist values for assets
    updateAssetPicklist() {
        this.relatedAssets = [];
        for (let i = 0; i < this.assets.length; i++) {
            if (typeof this.assets[i].make !== 'undefined') {
                this.relatedAssets.push({label: this.assets[i].assetHeading, value: this.program + '!@#$%^&*(' + this.assets[i].makeId + '!@#$%^&*(' + this.assets[i].assetTypeId + '!@#$%^&*(' + this.assets[i].modelId + '!@#$%^&*(' + this.assets[i].assetNo + '!@#$%^&*(' + this.assets[i].make + '!@#$%^&*(' + this.assets[i].model});
            }
        }
    }

    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
    //handlers for picklists
    onInputChange(event) {
        this[event.target.name] = event.target.value;
        this.quoteObject[event.target.name] = event.target.value;
    }

    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
    handleChange(event) {

        console.log('event target value: ' + event.target.value);

        this[event.target.name] = event.target.value;
        //Geetha - new code for unitprice //edit/copy asset PBI 882069
        //MRM - was not working  from used to new
        //if(event.target.value == 'Used'){
            this.template.querySelectorAll("c-assetcreation").forEach(element=>{
                element.resetUnitPrice();
            })
            this.assets.forEach(a=>{
                a.unitSalesPrice = undefined;
          })
          //callout for Leasetype and Ratetype
          this.loadTerms();

        //}
        this.quoteObject[event.target.name] = event.target.value;
        this.loadRates();
    }

    
    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
    handleChangeSalesRep(event) {
        if (!event.target || (event.target === {}) || (typeof event.target.value === 'undefined')) {
            return;
        }
        
        this.salesRep = this.salesRepList.find(element => element.value === event.target.value).label;
        this.quoteObject.salesRep = event.target.value;
        
        if (this.isLoadedQuote) {
            return;
        }

        if (this.osidForSalesReps.length !== 0) {
            for (let i = 0; i < this.osidForSalesReps.length; i++) {
                if (event.target.value === this.osidForSalesReps[i].value) {
                    this.location = this.osidForSalesReps[i].osid;
                    this.quoteObject.location = this.location;
                    let dummyEventSecond = {value: this.osidForSalesReps[i].osid, name: 'location'};
                    let dummyEvent = {target: dummyEventSecond};
                    this.handleChangeLocation(dummyEvent);
                }
            }
        }

    }

    
    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
    displayModalToFalse(event) {
        this.displayModal = false;
    }

    
    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
    displayModalToTrue(event) {
        this.displayModal = true;
    }

    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
    handleDependentRatesPicklistChange2(event) {

        this.loading = true;
        this[event.target.name] = event.target.value;
        this.quoteObject[event.target.name] = event.target.options.find(opt => opt.value === event.detail.value).label;
        this.quoteObject[event.target.name +'Id'] = event.target.value;

        //this.displayLocation = this.siteList.find(opt => opt.value === this.quoteObject.location).label;
        //this.displayProgram = this.quoteObject.program;

        //console.log(JSON.stringify(this.quoteObject)); 

        this.loadRates();

    }
    
    handleDependentRatesPicklistChange(message) {
        
        this.loading = true;

        this[name] = message;
        this.displayLocation = this.quoteObject.location;
        this.displayProgram = this.quoteObject.program;

        //console.log(JSON.stringify(this.quoteObject)); 
        this.loadRates();

    
    }

    
    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
    handleDependentTermsPicklistChange(event) {
        this.loading = true;
        this[event.target.name] = event.target.value;
        this.quoteObject[event.target.name] = event.target.options.find(opt => opt.value === event.detail.value).label;
        this.quoteObject[event.target.name +'Id'] = event.target.value;
     
        
        this.loadTerms();
        
    }

    
    
    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
    getSalesRepId(event) {
        this.quoteObject.salesRep = event.detail[0];
    }

    
    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
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

    
    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
    //tab toggle
    handleTabChange(event) {
        const tab = event.target;
        ////console.log(event.target.value);
        this.specificationTabActive = event.target.value === 'spec';
    }

    
    /***************************************************************************************************************
    *  handleAddOption  - this is for the +Add Option at the bottom of the options list.
    ***************************************************************************************************************/
    handleAddOption(event) {

        //seting the api option so that the call back in the child will switch over to new option upon call

        this.loading = true;
        this.newoption = 'New Option';
        this.optionsPicklistVal = this.newoption;
        this.currentTab = 'spec';
        this.loading = false;
        
    }

    
    
    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
    handleCancel(event) {

        

        //console.log('pricing component handle cancel');

        this.loading = true;
        this.displayModal = false;

        const passEvent = new CustomEvent('childcancel', {
            detail: {quote: this.quoteObject, activeTabValue:'proposal'} 
            });
            this.dispatchEvent(passEvent);


        
        
        this.loading = false;
    }

    
    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
    handleAddOption(event) {
        this.loading = true;

        this.activeOption = undefined;

        this.leaseTypeSummary = '-';
        this.rateTypeSummary = '-';
        this.advancedPaymentsSummary = '-';
        this.baseUnitSalesPriceSummary = '-';
        this.baseUnitSalesPriceWithoutDuplicatesSummary = '-';
        this.totalPaymentSummary = '-';
        this.residualSummary = '-';
        this.interestRateSummary = '-';
        this.termSummary = '-';

        let prog = this.quoteObject.program;
        let progId = this.quoteObject.programId;
        let loc = this.quoteObject.location;
        let salesId = this.quoteObject.salesRep;
        let assetTypeQuoteCopy = this.quoteObject.assetTypeQuote;

        if (this.options[0]) {
            prog = this.options[0].quote.Program__c;
            progId = this.options[0].quote.Program_ID__c;
            loc = this.options[0].quote.Location_ID__c;
            salesId = this.options[0].quote.Partner_Sales_Rep__c;
            assetTypeQuoteCopy = this.options[0].quote.Asset_Type__c;
        }

        this.quoteObject = {
            deleteAssets: [],
            financeType:'BO',
            paymentFrequency: 'Monthly',
            advPayments: '0',
            assetTypeQuote: assetTypeQuoteCopy,
            nickname: this.nickname,
            location: loc,
            salesRep: salesId,
            program: prog,
            programId: progId
        };

        if (this.opportunityId) {
            this.quoteObject.oppId = this.opportunityId;
            this.quoteObject.isEdit = false;
            this.quoteObject.isClone = true;
            this.showCreateInstead = true;
        } else {
            this.quoteObject.isEdit = false;
            this.quoteObject.isClone = false;
            this.showCreateInstead = true;
        }

        this.assets = [{
            sectionName: 'asset0',
            assetHeading: 'Asset 1',
            assetNo: 0,
            isFirst: true
        }];
        this.accessories = [{
            accNo: 0,
            accessoryHeading: 'Accessory 1',
            isFirst: true
        }];

        //finance attributes
        this.rateType = '';
        this.financeTerm = '';
        this.financeType = 'BO';
        this.paymentFrequency = 'Monthly';
        this.advPayments = '0';

        this.comments = '';
        setTimeout(() => {
            this.specificationTabActive = true;
            this.optionsPicklistVal = 'New Option';
            this.template.querySelector('lightning-tabset').activeTabValue = 'spec';
            this.loading = false;
        }, 500);
    }

    
    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
    //Option picklist handler
    handleOptionPicklist(event) {

     
        this.loading = true;
        this.optionsPicklistVal = event.target.value.toString();

        //console.log('hello' + this.optionsPicklistVal);

        if(this.optionsPicklistVal === 'New Option'){
            this.leaseTypeSummary = '-';
            this.rateTypeSummary = '-';
            this.advancedPaymentsSummary = '-';
            this.baseUnitSalesPriceSummary = '-';
            this.baseUnitSalesPriceWithoutDuplicatesSummary = '-';
            this.totalPaymentSummary = '-';
            this.residualSummary = '-';
            this.interestRateSummary = '-';
            this.termSummary = '-';

            this.activeOption = undefined;

            let prog = this.quoteObject.program;
            let progId = this.quoteObject.programId;
            let loc = this.quoteObject.location;
            let salesId = this.quoteObject.salesRep;
            let assetTypeQuoteCopy = this.quoteObject.assetTypeQuote;

            this.quoteObject = {
                deleteAssets: [],
                financeType:'BO',
                paymentFrequency: 'Monthly',
                advPayments: '0',
                assetTypeQuote: assetTypeQuoteCopy,
                nickname: this.nickname,
                salesRep: salesId,
                location: loc,
                program: prog,
                programId: progId
            };

            if (this.opportunityId) {
                this.quoteObject.oppId = this.opportunityId;
                this.quoteObject.isEdit = false;
                this.quoteObject.isClone = false;
                this.showCreateInstead = true;
            } else {
                this.quoteObject.isEdit = false;
                this.quoteObject.isClone = false;
                this.showCreateInstead = true;
            }

            this.assets = [{
                sectionName: 'asset0',
                assetHeading: 'Asset 1',
                assetNo: 0,
                isFirst: true
            }];

            //console.log('this assets is: ' + JSON.stringify(this.assets));

            this.accessories = [{
                accNo: 0,
                accessoryHeading: 'Accessory 1',
                isFirst: true
            }];
         
            //finance attributes
            this.rateType = '';
            this.financeTerm = '';
            this.financeType = 'BO';
            this.paymentFrequency = 'Monthly';
            this.advPayments = '0';

            this.comments = '';
        }else {
            
            //Values to be used by input fields
            this.quoteObject.isEdit = true;
            this.quoteObject.isClone = false;
            this.showCreateInstead = false;
            this.activeOption = event.target.value;
            this.quoteObject.optionNum = (this.optionsPicklistVal - 0) + 1;
            this.processAssets(this.options[event.target.value].quoteLines);
            this.processCurrentOption(this.options[event.target.value]);
        }

        if (event.skipLoadToFalse) {
            return;
        }

        this.loading = false;
         
    }


    
    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
    //Asset component handlers
    handleAddAsset(event) {
        this.loading = true;
        this.currentPosition = this.assets.length;
        this.assets.push({sectionName: 'asset' + this.currentPosition, assetHeading: 'Asset ' + (this.currentPosition + 1), assetNo: this.currentPosition, isFirst: false});
        //This timeout is needed since updating the accordion sections on the screen is async
        setTimeout(() => {
            this.openAccordionSections = ('asset' + this.currentPosition);
            this.loading = false;
        }, 500);
        
         
    }

    
    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
    handleDeleteAssetModal(event) {
        this.displayModalDelete = true;
        this.doAssetDeleteInstead = true;
        this.deleteAssetEventSavedForModal = event;
    }

    
    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
    handleDeleteAccessoryModal(event) {
        this.displayModalDelete = true;
        this.doAccessoryDeleteInstead = true;
        this.deleteAccessoryEventSavedForModal = event;
    }

    
    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
    handleDeleteAsset(event) {
        this.loading = true;
        
        ////console.log(event.detail);
        this.deleteRelatedAccessories(this.assets[event.detail]);
         
        if (typeof this.assets[event.detail].Id !== 'undefined') {
            this.quoteObject.deleteAssets.push({Id:this.assets[event.detail].Id});
        }
        this.assets.splice(event.detail, 1);
     

        this.currentPosition--;
        for (let i = 0; i < this.assets.length; i++) {
            this.assets[i].assetNo = i;
        }
         
        this.updateAssetPicklist();
         
        this.loading = false;
        
    }

    
    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
    handleUpdateAsset(event) {
        this.loading = true;
        
         

        for (let i = 0; i < this.assets.length; i++) {
            if (this.assets[i].modelId === this.assets[event.detail.assetNo].modelId
                && event.detail.assetNo !== i && event.detail.assetNo != undefined){
                    this.assets[event.detail.assetNo].modelId = undefined;
                    event.detail.modelId = undefined;
                    const evt = new ShowToastEvent({
                    title:      CREDITAPP_ASSET_TITLE,
                    message:    CREDITAPP_ASSET_DUP + ' ' + this.assets[i].model + '!',
                    variant:    'error', 
                    duration:   20000
                    });
                    this.dispatchEvent(evt);
                    this.loading = false;
                    return;
            }
        }

        this.assets[event.detail.assetNo] = event.detail;

        this.updateAssetPicklist();
        if (!this.saveRunning) {
            this.loading = false;
        }
         
    }

    
    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
    //Accessory Handlers
    //Asset component handlers
    handleAddAccessory(event) {
        this.loading = true;
        this.currentAccPosition++;
        this.accessories.push({accNo: this.currentAccPosition, accessoryHeading: 'Accessory ' + (this.currentAccPosition + 1), isFirst: false});
         
        this.loading = false;
         
    }

    
    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
    handleUpdateAccessory(event) {
        this.loading = true;
        this.accessories[event.detail.accNo] = event.detail;
        
        this.loading = false;
        
    }

    
    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
    handleDeleteAccessory(event) {
        this.loading = true;
         
        
        if (typeof this.accessories[event.detail].Id !== 'undefined') {
            this.quoteObject.deleteAssets.push({Id:this.accessories[event.detail].Id});
        }
        this.accessories.splice(event.detail, 1);
        this.currentAccPosition--;
        for (let i = 0; i < this.accessories.length; i++) {
            this.accessories[i].accNo = i;
            let headingStr = this.accessories[i].accessoryHeading.split(' ');
            headingStr[1] = i + 1;
            this.accessories[i].accessoryHeading = headingStr.join(' ');
        }
        if (this.accessories.length === 0) {
            this.accessories.push({
                accNo: 0,
                accessoryHeading: 'Accessory 1',
                isFirst: true
            });
            this.currentAccPosition = 0;
            //this.accessories = JSON.parse(JSON.stringify(this.accessories));
        }
        this.accessories = JSON.parse(JSON.stringify(this.accessories));
         
        this.loading = false;
     
    }

    
    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
    validateInputBeforeSave() {
     

        if ((typeof this.quoteObject.program === 'undefined') ||
            (typeof this.quoteObject.programId === 'undefined') ||
            (typeof this.quoteObject.nickname === 'undefined') ||
            (typeof this.quoteObject.location === 'undefined') ||
            (typeof this.quoteObject.assetTypeQuote === 'undefined')) {
            this.showToast('Error in fields in the quote header', 'Please fill out the entire quote header to be able to save.', 'error');
            return false;
        }

        if (!this.onlyValidateHeader) {
            if ((typeof this.quoteObject.rateType === 'undefined') ||
                (typeof this.quoteObject.rateTypeId === 'undefined') ||
                (typeof this.quoteObject.financeTerm === 'undefined')) {
                this.showToast('Error in fields in the Financial Details', 'Please fill out the remaining financial details to be able to save.', 'error');
                return false;
            }

            for (let i = 0; i < this.assets.length; i++) {
                if ((typeof this.assets[i].unitSalesPrice === 'undefined') ||
                    (typeof this.assets[i].numberOfUnits === 'undefined')) {
                    this.showToast('Error in fields in at least one Asset', 'Please fill out the required fields in Asset ' + (i + 1) + ' to be able to save.', 'error');
                    return false;
                }
                if ((typeof this.assets[i].subsidy === 'undefined') ) {
                    this.showToast('Error in fields in at least one Asset', 'Please wait for subsidy to load in Asset ' + (i + 1) + ' to be able to save.', 'error');
                    return false;
                }
            }
        }

        return true;
    }

    validateAccessories(accArr) {
        let result = [];
        for (let i = 0; i < accArr.length; i++) {
            if ((typeof accArr[i].relatedAsset !== 'undefined') &&
                (typeof accArr[i].noOfUnits !== 'undefined') &&
                (typeof accArr[i].unitSalesPrice !== 'undefined') &&
                (typeof accArr[i].model !== 'undefined') &&
                (typeof accArr[i].modelId !== 'undefined')) {
                result.push(accArr[i]);
            }
        }
        /*if (result.length !== accArr.length) {
            this.showToast('Total accessories removed from incomplete data: ', accArr.length - result.length, 'error');
        }*/
        return result;
    }

    saveDLLComments(event) {veaccArr
        this.comments = event.detail.value;
    }

    handleOnSaveOnlyHeader(event) {
        this.onlyValidateHeader = true;
        this.handleOnSave(event);
    }

    //Save quote
    handleOnSave(event) {

        //console.log('in save');
     
        if (!this.validateInputBeforeSave()) {
            return;
        }
        this.saveRunning = true;
        this.isLoadedQuote = true;
        this.loading = true;
        this.quoteObject.comments = this.comments;
    
        if (typeof this.quoteObject.assetTypeQuote === 'undefined') {
            this.quoteObject.assetTypeQuote = 'New';
        }
        this.quoteObject.assets = this.assets;
        this.quoteObject.accessories = this.validateAccessories(this.accessories);
        this.quoteObject.oppId = this.opportunityId;
        this.quoteObject.nickname = this.nickname;
         
        let passingParam = JSON.stringify(this.quoteObject);
    
        //console.log('this quoteobject is: ' +  this.passingParamnickname + '-' + JSON.stringify(this.quoteObject));

        if (this.clone == true){
            this.quoteObject.isEdit = false;
            this.quoteObject.isClone = true;
        }
        
        if (this.quoteObject.isEdit) {
             
            this.triggerParentSave = true;
            this.editQuote(passingParam);
             
        } else if (this.quoteObject.isClone  || this.hasQuotes) {
         
            this.triggerParentSave = true;
            this.cloneQuote(passingParam);
         
        } else {
             
            this.createdQuote = true;
            this.createQuote(passingParam);
             
        }

        
        
        
    }
    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
    cloneQuote(passingParam) {
        cloneQuoteOption({jsonInput: passingParam})
            .then(result => {
                if (this.hasQuotes){
                    this.showToast('Quote option has been saved!', 'Quote was saved successfully', 'success');
                }
                else{
                    this.showToast('Quote has been copied!', 'Quote was copied successfully', 'success');
                }
             
                this.parseData(result);
                this.newoption = result.quoteOpportunityLineItems.length - 1;
                this.addMissingOptionSummary(result);
                this.saveRunning = false;
            })
            .catch(error => {
                //console.log(error);
                this.showToast('Error Saving Record.', error, 'error');
                this.loading = false;
                this.saveRunning = false;
            });
    }
    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
    editQuote(passingParam) {

        //this.loading = true;
        editQuoteOption({jsonInput: passingParam})
            .then(result => {
                this.showToast('Quote has been edited!', 'Quote was edited successfully', 'success');
                this.parseData(result);
                this.addMissingOptionSummary(result);
                this.saveRunning = false;
            })
            .catch(error => {
                ////console.log(JSON.stringify(error));
                this.showToast('An error has occurred trying to edit an option.', error, 'error');
                this.loading = false;
                this.saveRunning = false;
            });
    }

        
   
    //Second page implementations
    handleAssetEdit(event) {
        this.loading = true;
        this.quoteObject.isEdit = true;
        this.quoteObject.isClone = false;
        this.showCreateInstead = false;
        this.activeOption = event.detail;
        this.quoteObject.optionNum = (event.detail - 0) + 1;
        this.processAssets(this.options[event.detail].quoteLines);
        this.processCurrentOption(this.options[event.detail]);
        setTimeout( () => {//options picklist does not load fast enough
            this.specificationTabActive = true;
            this.optionsPicklistVal = event.detail;
            this.template.querySelector('lightning-tabset').activeTabValue = 'spec';
        }, 500);
    }

    handleAssetClone(event) {
        this.loading = true;
        this.quoteObject.isClone = true;
        this.quoteObject.isEdit = false;
        this.showCreateInstead = false;
        this.quoteObject.Id = null;
        this.activeOption = undefined;
        this.quoteObject.oppId = this.opportunityId;
        this.processAssets(this.options[event.detail].quoteLines);
        this.processCurrentOption(this.options[event.detail]);
        setTimeout( () => {//options picklist does not load fast enough
            this.specificationTabActive = true;
            this.optionsPicklistVal = event.detail;
            this.template.querySelector('lightning-tabset').activeTabValue = 'spec';
            this.loading = false;
        }, 500);

        //console.log('qo' + this.quoteObject);
    }

    handleAssetDelete(event) {
        this.currentDeleteId = event.detail;
        this.displayModalDelete = true;
    }

    displayModalDeleteToFalse(event) {
        this.displayModalDelete = false;
        this.doAssetDeleteInstead = false;
        this.deleteAssetEventSavedForModal = {};
        this.doAccessoryDeleteInstead = false;
        this.deleteAccessoryEventSavedForModal = {};
    }

    handleDelete(event) {

        //console.log('in handel delete');
        if (this.doAssetDeleteInstead) {
            this.handleDeleteAsset(this.deleteAssetEventSavedForModal);
            this.displayModalDeleteToFalse({});
            return;
        } else if (this.doAccessoryDeleteInstead) {
            this.handleDeleteAccessory(this.deleteAccessoryEventSavedForModal);
            this.displayModalDeleteToFalse({});
            return;
        }
        this.loading = true;
        this.deleteQuote(this.currentDeleteId);
        if (this.currentDeleteId === this.creditAppId) {
            this.creditAppId = undefined;
            this.hasNoActiveQuoteForCredApp = true;
        }
        this.displayModalDelete = false;
    }

    deleteRelatedAccessories(assets) {
        let tempAcc = JSON.parse(JSON.stringify(this.accessories));
        this.accessories = [];
        for (let i = 0; i < tempAcc.length; i++) {
            if (!(parseInt(tempAcc[i].relatedAsset) === parseInt(assets.assetNo))) {
                this.accessories.push(tempAcc[i]);
                this.currentAccPosition--;
            }
        }
        if (this.accessories.length === 0) {
            this.accessories.push({
                accNo: 0,
                accessoryHeading: 'Accessory 1',
                isFirst: true
            });
        } else {
            for (let i = 0; i < this.accessories.length; i++) {
                this.accessories[i].accNo = i;
                this.currentAccPosition = i;
            }
            this.accessories[0].isFirst = true;
        }
    }

    addPricingDataToQuoteLines(response, quote, jsonString) {
        let addDataBackToServer = [];
        let residualTotal = 0;
        for (let i = 0; i < response.assets.length; i++) {
            for (let j = 0; j < quote.quoteLines.length; j++) {
                if (response.assets[i].sequenceId === quote.quoteLines[j].Id) {
                    quote.quoteLines[j].payment = response.assets[i].paymentAmount;
                    quote.quoteLines[j].interestRate = (parseFloat(jsonString.Interest__c)).toFixed(2) + '%';
                    let objToAdd = {};
                    if (response.assets[i].bookedResidualAmount) {
                        objToAdd.Booked_Residual_Amount__c = response.assets[i].bookedResidualAmount;
                        quote.quoteLines[j].closeAt = response.assets[i].bookedResidualAmount;
                        residualTotal += parseFloat(response.assets[i].bookedResidualAmount);
                    } else {
                        objToAdd.Booked_Residual_Amount__c = 0;
                        quote.quoteLines[j].closeAt = 0;
                    }
                    if (response.assets[i].billedResidualAmount) {
                        objToAdd.Billed_Residual_Amount__c = response.assets[i].billedResidualAmount;
                    } else {
                        objToAdd.Billed_Residual_Amount__c = 0;
                    }
                    objToAdd.Id = quote.quoteLines[j].Id;
                    objToAdd.Payment_Amount__c = response.assets[i].paymentAmount;
                    addDataBackToServer.push(objToAdd);
                    break;
                }
            }
            for (let k = 0; k < response.assets[i].assetComponents.length; k++) {
                for (let j = 0; j < quote.quoteLines.length; j++) {
                    if (response.assets[i].assetComponents[k].sequenceId === quote.quoteLines[j].Id) {
                        quote.quoteLines[j].payment = response.assets[i].assetComponents[k].paymentAmount;
                        quote.quoteLines[j].interestRate = (parseFloat(jsonString.Interest__c)).toFixed(2) + '%';
                        let objToAdd = {};
                        if (response.assets[i].assetComponents[k].bookedResidualAmount) {
                            objToAdd.Booked_Residual_Amount__c = response.assets[i].assetComponents[k].bookedResidualAmount;
                            quote.quoteLines[j].closeAt = response.assets[i].assetComponents[k].bookedResidualAmount;
                            residualTotal += parseFloat(response.assets[i].assetComponents[k].bookedResidualAmount);
                        } else {
                            objToAdd.Booked_Residual_Amount__c = 0;
                            quote.quoteLines[j].closeAt = 0;
                        }
                        if (response.assets[i].assetComponents[k].billedResidualAmount) {
                            objToAdd.Billed_Residual_Amount__c = response.assets[i].assetComponents[k].billedResidualAmount;
                        } else {
                            objToAdd.Billed_Residual_Amount__c = 0;
                        }
                        objToAdd.Id = quote.quoteLines[j].Id;
                        objToAdd.Payment_Amount__c = response.assets[i].assetComponents[k].paymentAmount;
                        //objToAdd.Total_Sales_Price__c = response.assets[i].assetComponents[k].financedAmount;
                        addDataBackToServer.push(objToAdd);
                        break;
                    }
                }
            }
        }
        if (addDataBackToServer.length !== 0) {
            saveQuoteLinePricingDataBackToServer({quoteString : JSON.stringify(addDataBackToServer)})
                .then(result => {
                    //this.showToast('Success saving quote line data', result, 'success');
                }).catch(error => {
                this.showToast('Something went wrong saving data for quote lines', JSON.stringify(error), 'error');
            });
        }
        return residualTotal;
    }

    removeDuplicateQuoteFromQOS(searchId) {
        for (let i = 0; i < this.quoteObjectSummary.length; i++) {
            if (this.quoteObjectSummary[i].quote.Id === searchId) {
                this.quoteObjectSummary.splice(i, 1);
                break;
            }
        }
    }

    /*****************************************************************************************************
     * Here is the call price; and a save
     * 
     * 
     * 
     */
    
    processPricingSummary(quoteObj) {

        this.loading = true;
         
        let lastBit = quoteObj.quote.Program_ID__c.split('.');
        lastBit = lastBit[lastBit.length - 1];

        let currentDate1 = new Date();
        let time1 = currentDate1.getHours() + ":" + currentDate1.getMinutes() + ":" + currentDate1.getSeconds() + 
             ":"  + currentDate1.getMilliseconds(); 
        //console.log(time1);
        //console.log('start get price' + time1);
        getPrice({"quoteId" : quoteObj.quote.Id, "programId" : quoteObj.quote.Program_ID__c, "siteId" : quoteObj.quote.Location_ID__c})
            .then(result => {
                let currentDate2 = new Date();
                    let time2 = currentDate2.getHours() + ":" + currentDate2.getMinutes() + ":" 
                    + currentDate2.getSeconds() + 
                         ":" + currentDate2.getMilliseconds(); 
                //console.log('end get price' + time2);
                this.loading = true;
                let resultParsed = JSON.parse(result);
                
                let quotePricingAPIData = {};
                quotePricingAPIData.Id = quoteObj.quote.Id;
                quotePricingAPIData.Amount__c = resultParsed.financeAmount;
                quotePricingAPIData.Interest__c = resultParsed.monthlyAPR;
                quotePricingAPIData.Total_Payment__c = resultParsed.paymentAmount;
                quotePricingAPIData.Residual__c = this.addPricingDataToQuoteLines(resultParsed, quoteObj, quotePricingAPIData);
                saveQuotePricingDataBackToServer({"quoteString" : JSON.stringify(quotePricingAPIData)})
                    .then(result => {
                        let newQuoteSummary = JSON.parse(JSON.stringify(quoteObj));
                        this.removeDuplicateQuoteFromQOS(quoteObj.quote.Id);
                        newQuoteSummary.sumData = [];
                        let sumDataContents = {};
                        sumDataContents.Amount__c = resultParsed.financeAmount;
                        sumDataContents.interestRate = parseFloat(resultParsed.monthlyAPR).toFixed(2) + '%';
                        sumDataContents.closeAt = quotePricingAPIData.Residual__c;
                        sumDataContents.payment = resultParsed.paymentAmount;
                        newQuoteSummary.sumData.push(sumDataContents);
                        if (this.quoteObjectSummary) {
                            this.quoteObjectSummary.push(newQuoteSummary);
                        } else {
                            this.quoteObjectSummary = [];
                            this.quoteObjectSummary.push(newQuoteSummary);
                        }
                
                        this.addOptionSummaries(true);
                        this.quoteObject.isEdit = false;
                    })
                    .catch(error => {
                        this.showToast('Error saving Pricing Summary Information.', error, 'error');
                    });
                
                
            })
            .catch(error => {
                this.showToast('Error getting Pricing Summary Information.', error, 'error');
                this.pricingApiCallCount--;
                if (this.pricingApiCallCount === 0) {
                    this.loading = false;
                }
            });
    }

    /********************************************************************************************************
     * 
     * this is where call pricing and save process driven.  processPricingSummary
     * 
     * MRM - changed it from recalling pricing and saving for every option to just the option that changed
     * for situations when there are many options this was nuts.  
     * 
     * 
     */
    addMissingOptionSummary(resultArr) {

        this.loading = true;
        //console.log('this option' + JSON.stringify(this.quoteObject) + '====> this options: ' + JSON.stringify(this.options));
        //console.log('this opton pic val: ' + this.quoteObject.optionNum);

        this.pricingApiCallCount = this.options.length; //0Q078000000HP9uCAG
        let match = null;

        //console.log('save process is beginning for:' + this.newoption);

        //if this is a new qutoe, first option, then newoption needs to be set to 0 for save;

        if (typeof this.newoption === 'undefined')
            this.newoption = 0;

        for (let i = 0; i < this.options.length; i++) {
            if ( i == this.newoption){
                match = i;
                
            }
            let myOpt = parseInt(this.quoteObject.option);
            myOpt = myOpt - 1;
             
            
        }

        this.processPricingSummary(this.options[match]);

        
    }

    addOptionSummaries(setCurrentOption) {

        this.loading = true;

        //console.log('in addOptionSummaries: ' + setCurrentOption);
         
        this.addPricingDataToLoadedQuotes();
         
        //console.log(this.quoteObjectSummary.length);
        //console.log(this.options.length);
        for (let i = 0; i < this.quoteObjectSummary.length; i++) {
            for (let j = 0; j < this.options.length; j++) {
                if (this.quoteObjectSummary[i].quote.Id === this.options[j].quote.Id) {
                    //console.log('Inside addOptionSummaries assignment');
                    this.options[j].sumData = this.quoteObjectSummary[i].sumData;
                    break;
                }
            }
        }
        if ((this.options.length > 0) && this.options[0].quote.Partner_Sales_Rep__r) {
            this.salesRepDisplayName = this.options[0].quote.Partner_Sales_Rep__r.Name;
        }
        if (setCurrentOption && (this.options.length !== 0)) {
            this.hasQuotes = true;
            this.hasLocationSelection = true;
            this.hasLocationSelectionSalesRep = false;
            if (typeof this.activeOption === 'undefined') {
                this.processAssets(this.options[this.options.length - 1].quoteLines);
                this.processCurrentOption(this.options[this.options.length - 1]);
                this.optionsPicklistVal = (this.optionsPicklist.length - 2).toString();
                if (this.optionsPicklist.length < 2) {
                    this.optionsPicklistVal = '0';
                }
                this.quoteObject.isEdit = true;
                this.quoteObject.isClone = false;
            } else {
                this.processAssets(this.options[this.activeOption].quoteLines);
                this.processCurrentOption(this.options[this.activeOption]);
                this.optionsPicklistVal = this.activeOption;
                this.quoteObject.isEdit = true;
                this.quoteObject.isClone = false;
            }
        } else if (this.options.length !== 0) {
            this.hasQuotes = true;
            this.hasLocationSelection = true;
            this.hasLocationSelectionSalesRep = false;
            this.processAssets(this.options[0].quoteLines);
            this.processCurrentOption(this.options[0]);
            this.optionsPicklistVal = '0';
            this.quoteObject.isEdit = true;
            this.quoteObject.isClone = false;
        } else {
            this.optionsPicklistVal = 'New Option';
            this.handleCancel();
        }
        
    
        if (this.optionsPicklistVal === 0) {
            this.optionsPicklistVal = this.optionsPicklistVal.toString();
        }
        this.options = JSON.parse(JSON.stringify(this.options));

        this.loading = true;
         
         
        const passEvent = new CustomEvent('childsave', {
            detail: {oppid: this.oppid, quote: this.quoteObject, activeTabValue:'proposal'} 
        });
        this.dispatchEvent(passEvent);
            
    }

    //save methods to backend For quote creation,edit,clone
    createQuote(passingParam) {

        this.loading = true;
        createQuoteOpportunity({jsonInput: passingParam})
            .then(result => {

                this.parseData(result);
                this.oppid = result.newOpp.Id;

                if (!this.onlyValidateHeader) {
                    this.addMissingOptionSummary(result);
                    this.hasQuotes = true;
                    this.specificationTabActive = false;
                   
                } else {
                    this.hasLocationSelection = true;
                    if ((this.options.length > 0) && this.options[0].quote.Partner_Sales_Rep__r) {
                        this.salesRepDisplayName = this.options[0].quote.Partner_Sales_Rep__r.Name;
                    }
                }
                
                this.saveRunning = false;
                this.onlyValidateHeader = false;
                this.showToast('Quote has been created!', 'Quote was created successfully', 'success');
            })
            .catch(error => {
                //console.log(JSON.stringify(error));
                this.showToast('Error Saving Record.', error, 'error');
                this.loading = false;
                this.saveRunning = false;
            });
    }
     

    
   
    addPricingDataToLoadedQuotes() {
        for (let i = 0; i < this.options.length; i++) {
            let arr = [];
            let sumDataEntry = {};
            sumDataEntry.Amount__c = this.options[i].quote.Amount__c;
            sumDataEntry.interestRate = (parseFloat(this.options[i].quote.Interest__c)).toFixed(2) + '%';
            sumDataEntry.payment = this.options[i].quote.Total_Payment__c;
            sumDataEntry.closeAt = this.options[i].quote.Residual__c;
            arr.push(sumDataEntry);
            this.options[i].sumData = arr;
        }
    }

    sortQuoteLinesByAccessories(option) {
        let sortedArr = [];
        let currentAssetNum = 0;
        for (let i = 0; i < option.quoteLines.length; i++) {
            if (option.quoteLines[i].Equipment_Type__c === 'Asset') {
                currentAssetNum++;
                let isEven = (currentAssetNum % 2) === 0;
                option.quoteLines[i].assetNumber = currentAssetNum;
                option.quoteLines[i].groupByAsset = (isEven) ? 'slds-color__background_gray-4' : '';
                option.quoteLines[i].closeAt = option.quoteLines[i].Booked_Residual_Amount__c;
                option.quoteLines[i].interestRate = (parseFloat(option.quote.Interest__c)).toFixed(2) + '%';
                if (option.quoteLines[i].Payment_Amount__c) {
                    option.quoteLines[i].payment = option.quoteLines[i].Payment_Amount__c;
                }
                sortedArr.push(option.quoteLines[i]);
                for (let j = 0; j < option.quoteLines.length; j++) {
                    if (option.quoteLines[i].Id === option.quoteLines[j].Related_Asset__c) {
                        option.quoteLines[j].assetNumber = ' ';
                        option.quoteLines[j].groupByAsset = option.quoteLines[i].groupByAsset;
                        option.quoteLines[j].interestRate = (parseFloat(option.quote.Interest__c)).toFixed(2) + '%';
                        option.quoteLines[j].closeAt = option.quoteLines[j].Booked_Residual_Amount__c;
                        option.quoteLines[j].Annual_Hours__c = option.quoteLines[i].Annual_Hours__c;
                        option.quoteLines[j].Operating_Environment__c = option.quoteLines[i].Operating_Environment__c;
                        if (option.quoteLines[j].Payment_Amount__c) {
                            option.quoteLines[j].payment = option.quoteLines[j].Payment_Amount__c;
                        }
                        sortedArr.push(option.quoteLines[j]);
                    }
                }
            }
        }
        return sortedArr;
    }

    //Process after successful result of quote save
    parseData(result) {
        ////console.log('start parseData');
        ////console.log(JSON.parse(JSON.stringify(result)));

        this.opportunityId = result.newOpp.Id;

        this.proposalIdsIncluded = [];

        this.displayNameForLocation = result.newOpp.Account.Name;
        this.displayNameForLocationPicklist = [{label: this.displayNameForLocation, value: this.displayNameForLocation}];

        this.options = result.quoteOpportunityLineItems.sort((a,b) => {
            if (parseInt(a.quote.Option_Number__c) > parseInt(b.quote.Option_Number__c)) {
                return 1;
            }
            if (parseInt(a.quote.Option_Number__c) < parseInt(b.quote.Option_Number__c)) {
                return -1;
            }
            return 0;
        });
        this.quoteNumber = result.newOpp.Opportunity_Number__c;

        if (this.onlyValidateHeader) {
            this.hasQuotes = true;
            this.specificationTabActive = false;
            this.loading = false;
            this.showToast('Quote has been saved!', 'Quote was saved successfully', 'success');
            return;
        }

        this.optionsPicklist = [];
        ////console.log('ol' + this.options.length);

        for (let i = 0; i < this.options.length; i++) {
            this.options[i].optionNumber = i + 1;
            this.options[i].optionIndex = i;
            this.optionsPicklist.push({value: i.toString(), label: 'Option ' + (i + 1)});
            for (let v = 0; v < this.options[i].quoteLines.length; v++) {
                //////console.log('Sequence Id is: ' + this.options[i].quoteLines[v].Sequence_ID__c);
                this.options[i].quoteLines[v].finance_term = this.options[i].quote.Term__c;
                this.options[i].quoteLines[v].rateType = this.options[i].quote.Rate_Type__c;
                this.options[i].quoteLines[v].financeType = this.options[i].quote.Lease_Type__c;
                this.options[i].quoteLines[v].Include_In_Proposal__c = this.options[i].quote.Include_In_Proposal__c;
                if (this.options[i].quoteLines[v].Related_Asset__c) {
                    this.options[i].quoteLines[v].Make__c = this.options[i].quoteLines[v].Model__c;
                }
            }
            if (this.options[i].quote.Include_In_Proposal__c) {
                this.proposalIdsIncluded.push(this.options[i].quote.Id);
            }
            if (this.options[i].quote.Current_Credit_App_Selection__c) {
                this.creditAppId = this.options[i].quote.Id;
                this.hasNoActiveQuoteForCredApp = false;
            }
            this.options[i].quoteLines = this.sortQuoteLinesByAccessories(this.options[i]);
        }
        this.optionsPicklist.push({value:'New Option', label:'New Option'});
        if (this.optionsPicklist.length === 2) {
            let wrapperEvent2 = {value: 0};
            let wrapperEvent = {target: wrapperEvent2, skipLoadToFalse: false};
            this.handleOptionPicklist(wrapperEvent);
            this.optionsPicklistVal = '0';
        }
        if (this.onlyValidateHeader) {
            this.hasQuotes = true;
            this.specificationTabActive = false;
            this.loading = false;
            this.showToast('Quote has been saved!', 'Quote was saved successfully', 'success');
        }
    }

    handleCreditAppRedirect(event) {
        ////console.log('In handlecreditappredirect');
        if (event.detail === 'refresh') {
            ////console.log('In handlecreditappredirect refresh');
            //setTimeout(() => {
            /*this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: '/dllondemand/s/new-quote?oppid=' + this.opportunityId
                }
            });*/
            this[NavigationMixin.Navigate](
                this.newPageReference,
                false
            );
            //document.location.search = '?oppid=' + this.opportunityId;
            setTimeout(() => {location.reload()}, 1000);
            //}, 10);
            ////console.log('In handlecreditappredirect refresh after');
        } else {
            this.showToast('Error','Unsuccessful redirect to credit application page', 'error');
        }
    }

    
    redirectToOpportunityPage(event) {
        if (this.opportunityId) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.opportunityId,
                    objectApiName: 'Opportunity',
                    actionName: 'view'
                }
            });
        }
    }

    sumOfQuoteLineBaseUnitPrice(qlarr) {
        let sum = 0;
        for (let i = 0; i < qlarr.length; i++) {
            if (qlarr[i].Base_Unit_Sales_Price__c) {
                sum += parseFloat(qlarr[i].Base_Unit_Sales_Price__c);
            }
        }
        return sum;
    }

    //Process response into front end implementation
    processCurrentOption(optionWithSumData) {
        
        let option = optionWithSumData.quote;

        let baseUnitSum;
        let totalPaymentSum;
        let interestRateSum;
        let totalResidualSum;

        if (optionWithSumData.sumData && optionWithSumData.sumData[0]) {
            if (optionWithSumData.sumData[0].Amount__c) {
                baseUnitSum = Number(optionWithSumData.sumData[0].Amount__c).toLocaleString();
                let checkForMissingZero = optionWithSumData.sumData[0].Amount__c.toString().split('.');
                if (checkForMissingZero[1] && (checkForMissingZero[1].length === 1)) {
                    checkForMissingZero[0] = Number(checkForMissingZero[0]).toLocaleString();
                    checkForMissingZero[1] = checkForMissingZero[1] + '0';
                    baseUnitSum = checkForMissingZero.join('.');
                } else if (checkForMissingZero.length === 1) {
                    baseUnitSum = baseUnitSum + '.00';
                }
            } else {
                baseUnitSum = 'Data Not Found';
            }

            if (optionWithSumData.sumData[0].payment) {
                totalPaymentSum = Number(optionWithSumData.sumData[0].payment).toLocaleString();
                let checkForMissingZero = optionWithSumData.sumData[0].payment.toString().split('.');
                if (checkForMissingZero[1] && (checkForMissingZero[1].length === 1)) {
                    checkForMissingZero[0] = Number(checkForMissingZero[0]).toLocaleString();
                    checkForMissingZero[1] = checkForMissingZero[1] + '0';
                    totalPaymentSum = checkForMissingZero.join('.');
                } else if (checkForMissingZero.length === 1) {
                    totalPaymentSum = totalPaymentSum + '.00';
                }
            } else {
                totalPaymentSum = 'Data Not Found';
            }
            if (optionWithSumData.sumData[0].closeAt) {
                totalResidualSum = Number(optionWithSumData.sumData[0].closeAt).toLocaleString();
                let checkForMissingZero = optionWithSumData.sumData[0].closeAt.toString().split('.');
                if (checkForMissingZero[1] && (checkForMissingZero[1].length === 1)) {
                    checkForMissingZero[0] = Number(checkForMissingZero[0]).toLocaleString();
                    checkForMissingZero[1] = checkForMissingZero[1] + '0';
                    totalResidualSum = checkForMissingZero.join('.');
                } else if (checkForMissingZero.length === 1) {
                    totalResidualSum = totalResidualSum + '.00';
                }
            } else {
                totalResidualSum = '0.00';
            }

            if (optionWithSumData.sumData[0].interestRate) {
                interestRateSum = optionWithSumData.sumData[0].interestRate;
            } else {
                interestRateSum = 'Data Not Found';
            }
        } else if (option) {
            if (option.Amount__c) {
                baseUnitSum = Number(option.Amount__c).toLocaleString();
                let checkForMissingZero = option.Amount__c.toString().split('.');
                if (checkForMissingZero[1] && (checkForMissingZero[1].length === 1)) {
                    checkForMissingZero[0] = Number(checkForMissingZero[0]).toLocaleString();
                    checkForMissingZero[1] = checkForMissingZero[1] + '0';
                    baseUnitSum = checkForMissingZero.join('.');
                } else if (checkForMissingZero.length === 1) {
                    baseUnitSum = baseUnitSum + '.00';
                }
            } else {
                baseUnitSum = 'Data Not Found';
            }

            if (option.Total_Payment__c) {
                totalPaymentSum = Number(option.Total_Payment__c).toLocaleString();
                let checkForMissingZero = option.Total_Payment__c.toString().split('.');
                if (checkForMissingZero[1] && (checkForMissingZero[1].length === 1)) {
                    checkForMissingZero[0] = Number(checkForMissingZero[0]).toLocaleString();
                    checkForMissingZero[1] = checkForMissingZero[1] + '0';
                    totalPaymentSum = checkForMissingZero.join('.');
                } else if (checkForMissingZero.length === 1) {
                    totalPaymentSum = totalPaymentSum + '.00';
                }
            } else {
                totalPaymentSum = 'Data Not Found';
            }
            if (option.Residual__c) {
                totalResidualSum = Number(option.Residual__c).toLocaleString();
                let checkForMissingZero = option.Residual__c.toString().split('.');
                if (checkForMissingZero[1] && (checkForMissingZero[1].length === 1)) {
                    checkForMissingZero[0] = Number(checkForMissingZero[0]).toLocaleString();
                    checkForMissingZero[1] = checkForMissingZero[1] + '0';
                    totalResidualSum = checkForMissingZero.join('.');
                } else if (checkForMissingZero.length === 1) {
                    totalResidualSum = totalResidualSum + '.00';
                }
            } else {
                totalResidualSum = '0.00';
            }

            if (option.Interest__c) {
                interestRateSum = (parseFloat(option.Interest__c)).toFixed(2) + '%';
            } else {
                interestRateSum = 'Data Not Found';
            }
        } else {
            baseUnitSum = 'Data Not Found';
        }

        this.leaseTypeSummary = option.Lease_Type__c;

        if (option.Lease_Type__c == 'BO')
            this.leaseTypeSummary = '$1 Buy out';
            
        this.rateTypeSummary = option.Rate_Type__c;
        this.advancedPaymentsSummary = option.Advance_Payments__c;
        this.baseUnitSalesPriceWithoutDuplicatesSummary = this.sumOfQuoteLineBaseUnitPrice(optionWithSumData.quoteLines).toString();
        let checkForMissingZero = this.baseUnitSalesPriceWithoutDuplicatesSummary.split('.');
        if (checkForMissingZero[1] && (checkForMissingZero[1].length === 1)) {
            checkForMissingZero[1] = checkForMissingZero[1] + '0';
            checkForMissingZero[0] = Number(checkForMissingZero[0]).toLocaleString();
            this.baseUnitSalesPriceWithoutDuplicatesSummary = checkForMissingZero.join('.');
        } else if (checkForMissingZero.length === 1) {
            this.baseUnitSalesPriceWithoutDuplicatesSummary = Number(this.baseUnitSalesPriceWithoutDuplicatesSummary).toLocaleString() + '.00';
        } else {
            checkForMissingZero[1] = checkForMissingZero[1].substring(0, 2);
            checkForMissingZero[0] = Number(checkForMissingZero[0]).toLocaleString();
            this.baseUnitSalesPriceWithoutDuplicatesSummary = checkForMissingZero.join('.');
        }
        this.baseUnitSalesPriceWithoutDuplicatesSummary = '$' + this.baseUnitSalesPriceWithoutDuplicatesSummary;
        this.baseUnitSalesPriceSummary = '$' + baseUnitSum;
        this.totalPaymentSummary = '$' + totalPaymentSum;
        this.interestRateSummary = interestRateSum;
        this.termSummary = option.Term__c;
        this.residualSummary = '$' + totalResidualSum;

        this.quoteObject.rateTypeId = option.Rate_Type_Id__c;
        this.quoteObject.rateType = option.Rate_Type__c;
        this.quoteObject.financeTerm =  option.Term__c;
        this.quoteObject.financeType = option.Lease_Type__c;
        this.quoteObject.paymentFrequency = option.Payment_Frequency__c;
        this.quoteObject.advPayments = option.Advance_Payments__c;
        this.quoteObject.program =option.Program__c;
        this.quoteObject.programId = option.Program_ID__c;
        this.quoteObject.Id = option.Id;
        this.quoteObject.nickname = option.Name;
        this.quoteObject.comments = option.Comments__c;
        this.quoteObject.salesRep = option.Partner_Sales_Rep__c;
        this.quoteObject.location = option.Location_ID__c;
        this.quoteObject.assetTypeQuote = option.Asset_Type__c;
        this.quoteObject.oppId = this.opportunityId;
        if (option.Partner_Sales_Rep__r) {
            this.salesRepDisplayName = option.Partner_Sales_Rep__r.Name;
            this.salesRep = option.Partner_Sales_Rep__r.Name;
        }
        this.program = option.Program_ID__c;
        this.rateType = option.Rate_Type_Id__c;
        this.financeTerm = option.Term__c;
        if (option.Lease_Type__c === 'Fair Market Value ( FMV )') {
            this.financeType = 'FMV';
        } else {
            this.financeType = 'BO';
        }
        this.paymentFrequency = option.Payment_Frequency__c;
        this.advPayments = option.Advance_Payments__c;
        this.comments = option.Comments__c;
        this.nickname = option.Name;
        this.assetTypeQuote = option.Asset_Type__c;
        this.loading = true;
        this.loadRates();

        
    }

    processAssets(assets) {
        this.assets = [];
        this.accessories = [];
        let currentAssetNum = 0;
        for (let i = 0; i < assets.length; i++) {
            if (assets[i].Equipment_Type__c !== 'Asset') {
                continue;
            }
            let tempAsset = {};
            tempAsset.make = assets[i].Make__c;
            tempAsset.makeId = assets[i].Make_Id__c;
            tempAsset.assetTypeId = assets[i].Asset_Type_ITA_Class_Id__c;
            tempAsset.assetType = assets[i].Asset_Type_ITA_Class__c;
            tempAsset.model =  assets[i].Model__c;
            tempAsset.modelId = assets[i].Model_Id__c;
            tempAsset.mastType = assets[i].Mast_Type__c;
            tempAsset.assetOperating = assets[i].Operating_Environment__c;
            tempAsset.annualHours = String(assets[i].Annual_Hours__c);
            tempAsset.numberOfUnits = String(assets[i].Number_of_Units__c);
            tempAsset.unitSalesPrice = String(assets[i].Base_Unit_Sales_Price__c);
            tempAsset.msrp = String(assets[i].MSRP__c);
            tempAsset.batteryIncluded = assets[i].Battery_Included__c;
            tempAsset.subsidyName = assets[i].Subsidy__c;
            ////console.log('subsidy stuf: ' + assets[i].Subsidy_ID__c);
            if (typeof assets[i].Subsidy_ID__c === 'undefined') {
                tempAsset.subsidy = 'No';
            } else {
                tempAsset.subsidy = assets[i].Subsidy_ID__c;
            }
            tempAsset.Id = assets[i].Id;
            tempAsset.assetNo = currentAssetNum;
            tempAsset.assetHeading = 'Asset ' + (currentAssetNum + 1) + ' | ' + tempAsset.make + ' ' + tempAsset.model;
            if (currentAssetNum === 0) {
                tempAsset.isFirst = true;
            }
            this.assets.push(tempAsset);
            currentAssetNum++;
        }
        if (this.assets.length !== 0) {
            this.updateAssetPicklist();
        }
        currentAssetNum = 0;
        for (let i = 0; i < assets.length; i++) {
            if (assets[i].Equipment_Type__c !== 'Asset') {
                let tempAccessory = {};
                let tempRelatedAsset = this.assets.find(ql => ql.Id === assets[i].Related_Asset__c);
                if (tempRelatedAsset) {
                    tempAccessory.relatedAssetTotal = this.program;
                    tempAccessory.relatedAssetTotal += '!@#$%^&*(' + tempRelatedAsset.makeId;
                    tempAccessory.relatedAssetTotal += '!@#$%^&*(' + tempRelatedAsset.assetTypeId;
                    tempAccessory.relatedAssetTotal += '!@#$%^&*(' + tempRelatedAsset.modelId;
                    tempAccessory.relatedAssetTotal += '!@#$%^&*(' + tempRelatedAsset.assetNo;
                    tempAccessory.relatedAssetTotal += '!@#$%^&*(' + tempRelatedAsset.make;
                    tempAccessory.relatedAssetTotal += '!@#$%^&*(' + tempRelatedAsset.model;
                    tempAccessory.relatedAsset = tempRelatedAsset.assetNo;
                }
                tempAccessory.Id = assets[i].Id;
                tempAccessory.noOfUnits = assets[i].Number_of_Units__c;
                tempAccessory.unitSalesPrice = assets[i].Base_Unit_Sales_Price__c;
                tempAccessory.accessoryPicklistValue = assets[i].Model_Id__c;
                tempAccessory.model = assets[i].Model__c;
                tempAccessory.modelId = assets[i].Model_Id__c;
                tempAccessory.accNo = currentAssetNum;
                if (currentAssetNum === 0) {
                    tempAccessory.isFirst = true;
                }
                currentAssetNum++;
                tempAccessory.accessoryHeading = 'Accessory ' + currentAssetNum;
                if (tempRelatedAsset) {
                    tempAccessory.accessoryHeading += ' | Asset ' + (parseInt(tempRelatedAsset.assetNo) + 1);
                    if (assets[i].Model__c) {
                        tempAccessory.accessoryHeading += ' | ' + assets[i].Model__c;
                    }
                }
                this.accessories.push(tempAccessory);
            }
        }
        if (this.accessories.length === 0) {
            this.accessories.push({
                accNo: 0,
                accessoryHeading: 'Accessory 1',
                isFirst: true
            });
        }
    }

    
    //Proposal Document -Geetha - start
    getBaseUrl(){
        let baseUrl = 'https://'+location.host+'/';
        /*getLoginURL()
        .then(result => {
            baseUrl = result;
            window.////console.log(baseUrl);
        })
        .catch(error => {
            console.error('Error: \n ', error);
        });*/
        return baseUrl;
    }


    handleCustomerInfoShow(event) {
        ////console.log('handle customer info show' + 'event.detail:' + event.detail + ' oppid:' + this.opportunityId);
        this.customerInfoShow=event.detail;

    }

}