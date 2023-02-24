/**
 * Created by ShiqiSun on 11/17/2021.  then tod could not add one more comment in 1 year.
*
*  Change Log:
*  07/22/2022 - MRM - made leasetype picklist dynamic based on asset condition.
*  10/6/2022 - Geetha - Fixed Bugs 870385, 868811
*  10/20/2022 - Geetha - PBI 882069 - As a portal user I want to edit/copy the asset condition of an existing quote option
*  11/17/2022 -0 MRM - Pricing 2.0; now reusable component for pricing
*/

import {api, track, LightningElement, wire} from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import {ShowToastEvent} from "lightning/platformShowToastEvent";

import {checkPermission} from 'c/dodJSUtility';//PBI-810432 - Dibyendu

//pricing stuff
import getUserSite from "@salesforce/apex/PricingUtils.getUserSite"; 
import getPrograms from "@salesforce/apex/PricingUtils.getPrograms";
import getFinancialProducts from "@salesforce/apex/PricingUtils.getFinancialProducts";
import getFinancialProduct from "@salesforce/apex/PricingUtils.getFinancialProduct";
import getSalesReps from "@salesforce/apex/PricingUtils.getSalesReps";
import getSalesRepsFromReturnedOSID from "@salesforce/apex/CreateQuoteOpportunity.getSalesRepsFromReturnedOSID";

//data manipulation items
import deleteQuoteOption from "@salesforce/apex/CreateQuoteOpportunity.DeleteQuoteOption";
import markQuoteOptionAsPrimary from "@salesforce/apex/CreateQuoteOpportunity.markQuoteOptionAsPrimary";
import markQuoteOptionAsCreditAppSelection from "@salesforce/apex/CreateQuoteOpportunity.markQuoteOptionAsCreditAppSelection";
import queryQuoteOpportunity from "@salesforce/apex/CreateQuoteOpportunity.QueryQuoteOpportunity";
import setProposalForQuote from "@salesforce/apex/CreateQuoteOpportunity.setProposalForQuote";
import saveCustomerCommentsToOpp from "@salesforce/apex/CreateQuoteOpportunity.saveCustomerCommentsToOpp";
import getSmartCommDoc from "@salesforce/apex/SmartCommUtils.getSmartCommDoc";



export default class PriceQuotePageContainerReplacment extends NavigationMixin(LightningElement) {

    // public property
    @api sectionTitle;
    @api sectionSubTitle;
    @api oppid;
    @api option;

    //Button/Link Permissions//PBI-810432 - Dibyendu
    DP01 = false;   
    DP02 = false; 


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
    newOption;
    options = [];
    show = false;
    opportunityId;
    optionFirstTime = true;

    @track quoteObject = {
        deleteAssets: [],
        isEdit: false,
        isClone: false,
        assetTypeQuote: 'New',
        financeType:'BO',
        paymentFrequency: 'Monthly',
        advPayments: '0',
        program: null,
        programId: null,
        location: null,
        locationId: null,
        nickname: null,
        option: null,
        optionNum: null
    };



    quoteObjectSummary = [];

    //trackers
    @track currentPosition = 0;
    @track currentAccPosition = 0;
    @track loading = false;
    @track hasQuotes = false;
    @track specificationTabActive = true;
    @track currentTab = 'proposal';
    @track optionsPicklistVal = '0';

    //Values to be used by input fields
    nickname = '';
    location;
    salesRep;
    program = '';
    assetTypeQuote = 'New';
    userSite;
    quoteNumber;

    //finance attributes
    rateType;
    
    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
    @api
    get isRateDisabled() {
        ////console.log('rate disab');
        let result = (this.program === '') || (this.assetTypeQuote === '') || (this.location === '') || (this.nickname === '');
        if (!result && (this.openAccordionSections.length === 0)) {
            this.openAccordionSections = ['Finance Structure'];
        } else if (result && this.openAccordionSections.includes('Finance Structure') && (this.openAccordionSections.length === 1)) {
            this.openAccordionSections = [];
        }
        return result;
    }
     

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

    @api displayModal = false;

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
    *  
    ***************************************************************************************************************/
    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        //console.log('in wire');
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

    get newPageReferenceUrlParams() {
        return {
            oppid: this.opportunityId
        };
    }

    
    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
    setCurrentPageIdBasedOnUrl() {
        this.oppid = this.currentPageReference.state.oppid;
    }

    //method to check if the permission is true or false; this drives display of the button or link//PBI-810432 - Dibyendu
    async setPermissions() {    
            this.DP01 = await checkPermission('DP01'); 
            this.DP02 = await checkPermission('DP02'); 
            //this.CQ01 =  checkPermission('CQ01'); 
           // alert('CQ01:'+this.CQ01.value);
    
    }

    renderedCallback() {
        alert('CQ01:'+this.DP01);
        console.log('render Value1',this.DP01);
        console.log('render Value1',this.DP02);
        this.setPermissions();
       /* setTimeout(() => {
            //this.loading = false;
            console.log('render Value2',this.DP03);
            
        }, 2000);*/
        console.log('render Value2',this.DP01);
        console.log('render Value2',this.DP02);
    }

    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
    connectedCallback() {
        
        //console.log(this.oppid);
        this.loading = false;

        if (this.oppid) {
            this.loading = true;
            this.isLoadedQuote = true;
            queryQuoteOpportunity({'oppId' : this.oppid})
                .then(result => {
                    this.parseData(result);
                    this.addPricingDataToLoadedQuotes();
                    if (this.options.length !== 0) {
                        this.hasQuotes = true;
                        this.hasLocationSelection = true;
                        this.hasLocationSelectionSalesRep = false;
                        this.specificationTabActive = false;
                        this.program = this.options[0].quote.Program__c;
                        if (this.optionsPicklist.length > 1) {
                            let wrapperEvent2 = {value: 0};
                            let wrapperEvent = {target: wrapperEvent2, skipLoadToFalse: false};
                            this.handleOptionPicklist(wrapperEvent);
                            this.optionsPicklistVal = '0';
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
                            this.loading = true;
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
                                        //if (loadsToGo === 0) {
                                        //    this.loading = false;
                                        //}
                                    }, 1500);
                                }).catch(error => {
                                ////console.log(JSON.parse(JSON.stringify(error)));
                                this.showToast('Something went wrong', error.body.message, 'error');
                                loadsToGo--;
                                //if (loadsToGo === 0) {
                                //    this.loading = false;
                                //}
                                this.programPicklist = undefined;
                                return;
                            });
                            this.loading = true;
                             
                            getSalesReps({ originatingSiteId: this.location })
                                .then(result => {


                                    let data = JSON.parse(result);
                                    let sList = [];

                                    data.forEach(function(element){

                                        sList.push({label: element.name, value: element.id});

                                    });

                                    sList.push({label: 'None', value: ''});

                                    this.salesRepList = sList;
                                    this.salesRepListBackup = sList;
                                    ////console.log('getSalesReps1 Done');
                                    ////console.log(JSON.parse(JSON.stringify(sList)));
                                    //this.salesRep = this.options[0].quote.Partner_Sales_Rep__c;
                                    loadsToGo--;
                                    // if (loadsToGo === 0) {
                                    //    this.loading = false;
                                    //}


                                })
                                .catch(error => {
                                    loadsToGo--;
                                    //if (loadsToGo === 0) {
                                    //    this.loading = false;
                                    //}
                                    this.showToast('Something went wrong', error.body.message, 'error');
                                });
                             
                            
                        }
                    }
                    //this.loading = false;
                }).catch(error => {
                    this.showToast('Invalid Opportunity Id', this.oppid, 'error');
                    ////console.log('Opportunity Import Error:' + error);
                    ////console.log(JSON.parse(JSON.stringify(error)));
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

    //Wire methods
    /***********************************************************************************************************
     * getUserSIte
     ************************************************************************************************************/
    @wire(getUserSite, {userId: null})
    wiredgetUserSite({error, data}) {
        this.loading = true;
        this.advance = '0';
        this.frequency = 'monthly';
        ////console.log('in getUserSite');

        if (data) {
            let parsedData = JSON.parse(data);
            ////console.log(JSON.parse(JSON.stringify(data)));
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
                        ////console.log('getSalesRepsOSID Done');
                        ////console.log(JSON.parse(JSON.stringify(sList)));
                        this.osidForSalesReps = osidList;
                        //this.loading = false;
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
        //setTimeout(() => {
            //this.loading = false;

            ////console.log('wiredGetUserSite done');
        //}, 1500);
    }

    
    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
    handleChangeLocation(event) {
        this[event.target.name] = event.target.value;
        this.quoteObject[event.target.name] = event.target.value;
        
        ////console.log('qutoe objasdfa: ' + JSON.stringify(this.quoteObject));

        this.refreshSalesRepDropdown = false;

        this.loading = true;
        if (!this.program) {
            this.hasLocationSelection = false;
        }
        this.hasLocationSelectionSalesRep = false;

        

        let loadsToGo = 2;

        getPrograms({siteName: event.target.value})
            .then(result => {
                let plist = [];
                let data = JSON.parse(result);
                let hasProgramId = false;
                data.forEach(function (element) {
                    ////console.log(element.programName + ' ' + element.programId);
                    plist.push({label: element.programName, value: element.programId});

                });
                for (let i = 0; i < plist.length; i++) {
                    if (this.program === plist[i].value) {
                        hasProgramId = true;
                    }
                }
                if (!hasProgramId) {
                    this.hasLocationSelection = false;
                    this.program = '';
                    this.quoteObject.program = undefined;
                    this.quoteObject.programId = undefined;
                }
                this.programPicklist = plist;
                setTimeout(() => {
                    loadsToGo--;
                    if (loadsToGo === 0) {
                        //this.loading = false;

                        ////console.log('handleChangeLocation done2');
                         
                       
                    }
                }, 1500);
            }).catch(error => {
            ////console.log(JSON.parse(JSON.stringify(error)));
            this.showToast('Something went wrong', error.body.message, 'error');
            loadsToGo--;
            if (loadsToGo === 0) {
                //this.loading = false;
            }
            this.programPicklist = undefined;
            return;
        });

        getSalesReps({ originatingSiteId: event.target.value })
            .then(result => {



                let data = JSON.parse(result);
                let sList = [];
                let currentSalesRep = this.quoteObject.salesRep;
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
                    ////console.log('sales rep removed');
                    //this.salesRepList = JSON.parse(JSON.stringify(this.salesRepList));
                    this.salesRep = '';
                    this.quoteObject.salesRep = '';
                }

                this.refreshSalesRepDropdown = true;

                ////console.log('getSalesReps2 Done');
                ////console.log(JSON.parse(JSON.stringify(sList)));
                loadsToGo--;
                if (loadsToGo === 0) {
                    //this.loading = false;

                    ////console.log('handleChangeLocation done');
                }


            })
            .catch(error => {
                loadsToGo--;
                if (loadsToGo === 0) {
                    this.loading = false;
                }
                this.showToast('Something went wrong', error.body.message, 'error');
            });

    }

    
    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
    //Functions for loading in dependent picklist values
    loadRates() {
        //console.log('this asstypequote' + this.assetTypeQuote );

        this.loading = true;
        
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
                        //console.log('loadRates done2');
                        this.loading = false;
                        return;
                    }

                }
                 
                this.rateTypePicklist = plist;
                this.loading = false;

                //console.log('loadRates done');

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
    loadTerms() {

        //console.log('in load terms replacement');

        this.loading = true;

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
                    //this.loading = false;
                }

                ////console.log('loadTerms done x');
                this.loading = false;
                ////console.log(this.pricingApiCallCount);

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
    handleQuoteSelectForCreditApp(event) {
        this.creditAppId = event.detail;
        this.hasNoActiveQuoteForCredApp = false;
         
        this.loading = true;
        //console.log('event detail:' + event.detail);

        markQuoteOptionAsCreditAppSelection({quoteId : this.creditAppId, oppId : this.opportunityId})
            .then(result => {
                if (result == 'NoPayment'){
                    this.creditAppId = null;
                    this.hasNoActiveQuoteForCredApp = true;
                    this.showToast('This option cannot be selected because there is no valid payment!', 'Error', 'error');
                    this.loading = false;
                    return;
                }
                this.showToast('Success saving selection', 'Success', 'success');
                this.loading = false;
            }).catch(error => {
            this.showToast('Error in saving selection','Error', 'error');
            this.loading = false;
        });

        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: window.location.origin + '/dllondemand/s/quotetestpage?oppid=' + this.oppid
            }
        });
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
    *  change event for asset condition
    ***************************************************************************************************************/
    handleChange(event) {

        //console.log('calling' + this.currentTab);

        if (this.currentTab == 'spec'){
            this.template.querySelector('c-pricing-component').childCondition(event.target.value);
        }


    }

    
    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
    handleChangeSalesRep(event) {
        if (!event.target || (event.target === {}) || (typeof event.target.value === 'undefined')) {
            return;
        } else {
            this.salesRep = '';            
            event.target.inputValue = '';    
        }

        //////console.log(this.salesRepList);
        //////console.log(event.target.value);
        this.salesRep = this.salesRepList.find(element => element.value === event.target.value).label;
        this.quoteObject.salesRep = event.target.value;
        ////console.log('In change function');
        ////console.log(JSON.parse(JSON.stringify(this.quoteObject)));

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
    handleDependentRatesPicklistChange(event) {  //keep to call child

        this.loading = true;

        this[event.target.name] = event.target.value;
        this.quoteObject[event.target.name] = event.target.options.find(opt => opt.value === event.detail.value).label;
        this.quoteObject[event.target.name +'Id'] = event.target.value;

        this.displayLocation = this.siteList.find(opt => opt.value === this.quoteObject.location).label;
        this.displayProgram = this.quoteObject.program;
       
        if (this.quoteObject.location != null && this.quoteObject.programId != null){
            
            this.template.querySelector('c-pricing-component').childPricing(this.quoteObject);

        }

        this.loading = false;
        
    }

    
    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
    handleDependentTermsPicklistChange(event) {
        this.loading = true;
        this[event.target.name] = event.target.value;
        this.quoteObject[event.target.name] = event.target.options.find(opt => opt.value === event.detail.value).label;
        this.quoteObject[event.target.name +'Id'] = event.target.value;
        ////console.log(JSON.stringify(this.quoteObject));
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
        ////console.log('************* tab change ' + event.target.value);
        this.currentTab = event.target.value;
        const tab = event.target;
        ////console.log(event.target.value);
        this.specificationTabActive = event.target.value === 'spec';
        
    }

    
    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
    handleCancel(event) {

        //console.log('handle cancel');
        this.loading = true;
        this.displayModal = false;

        this.activeOption = undefined;

        let prog;
        let progId;
        let loc;
        let salesId;
        let quoteNickname;
        let assetTypeQuoteCopy;

        if (this.hasQuotes) {
            this.specificationTabActive = false;
            this.optionsPicklistVal = 'New Option';
            this.template.querySelector('lightning-tabset').activeTabValue = 'proposal';
            prog = this.quoteObject.program;
            progId = this.quoteObject.programId;
            loc = this.quoteObject.location;
            salesId = this.quoteObject.salesRep;
            assetTypeQuoteCopy = this.quoteObject.assetTypeQuote;
            quoteNickname = this.nickname;
        } else {
            prog = undefined;
            progId = undefined;
            loc = undefined;
            salesId = undefined;
            quoteNickname = undefined;
            assetTypeQuoteCopy = undefined;
            this.nickname = undefined;
            this.salesRep = undefined;
            this.location = undefined;
            this.program = undefined;
            this.assetTypeQuote = undefined;
            this.hasLocationSelection = true;
            this.hasLocationSelectionSalesRep = true;
        }

        this.leaseTypeSummary = '-';
        this.rateTypeSummary = '-';
        this.advancedPaymentsSummary = '-';
        this.baseUnitSalesPriceSummary = '-';
        this.baseUnitSalesPriceWithoutDuplicatesSummary = '-';
        this.totalPaymentSummary = '-';
        this.residualSummary = '-';
        this.interestRateSummary = '-';
        this.termSummary = '-';

        this.quoteObject = {
            deleteAssets: [],
            financeType:'BO',
            paymentFrequency: 'Monthly',
            advPayments: '0',
            assetTypeQuote: assetTypeQuoteCopy,
            nickname: quoteNickname,
            program:  prog,
            programId: progId,
            location: loc,
            salesRep: salesId
        };

        if (this.opportunityId) {
            this.quoteObject.oppId = this.opportunityId;
            this.quoteObject.isEdit = false;
            this.quoteObject.isClone = true;
            this.showCreateInstead = true;
        } else {
            this.quoteObject.isEdit = false;
            this.quoteObject.isClone = false;
            this.showCreateInstead = false;
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
        //this.program = '';
        //this.assetTypeQuote = 'New';

        //finance attributes
        this.rateType = '';
        this.financeTerm = '';
        this.financeType = 'BO';
        this.paymentFrequency = 'Monthly';
        this.advPayments = '0';

        this.comments = '';
        setTimeout(() => {
            this.loading = false;
            ////console.log('handleCancel finished');
        }, 500);
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
    * handleOptionPicklist - this deals with switching between options.  1,2,3,4,...New Option  
    ***************************************************************************************************************/
    //Option picklist handler
    handleOptionPicklist(event) {

        
        this.loading = true;
        //console.log('*** in replacement calling option *** ' + this.loading);
        this.optionsPicklistVal = event.target.value.toString();
        //console.log('this op pick val' + this.optionsPicklistVal);
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
                programId: progId,
                option: this.optionsPicklistVal
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
         
            if (this.currentTab == 'spec'){
                this.template.querySelector('c-pricing-component').childOption(this.optionsPicklistVal);
            }
        }else {
            //Values to be used by input fields
            this.quoteObject.isEdit = true;
            this.quoteObject.isClone = false;
            this.showCreateInstead = false;
            this.activeOption = event.target.value;
            this.quoteObject.optionNum = (this.optionsPicklistVal - 0) + 1;
            this.processAssets(this.options[event.target.value].quoteLines);
            this.processCurrentOption(this.options[event.target.value]);
            
            if (this.currentTab == 'spec'){
                this.template.querySelector('c-pricing-component').childOption(this.optionsPicklistVal);
            }
        }
        if (event.skipLoadToFalse) {
            return;
        }

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
                if ((typeof this.assets[i].subsidy === 'undefined')) {
                    this.showToast('Error in fields in at least one Asset', 'Please wait for subsidy to load in Asset ' + (i + 1) + ' to be able to save.', 'error');
                    
                    return false;
                }
            }
        }

        return true;
    }

    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
    setCustomerComments(e) {
        this.customerComments = e.detail.value;
    }


    
    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
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
         
        return result;
    }

    
    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
    saveDLLComments(event) {
        this.comments = event.detail.value;
    }

    
    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
    handleOnSaveOnlyHeader(event) {
        this.onlyValidateHeader = true;
        //this.handleOnSave(event);
    }

    
    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
    //Second page implementations
    handleAssetEdit(event) {
        this.loading = true;
        this.quoteObject.isEdit = true;
        this.quoteObject.isClone = false;
        this.showCreateInstead = false;
        this.activeOption = event.detail;
        this.quoteObject.optionNum =  this.activeOption;
        this.quoteObject.option =  this.activeOption;
        this.newoption = this.activeOption;
        this.optionsPicklistVal = this.activeOption;
        
        
        this.processAssets(this.options[this.activeOption].quoteLines);
        this.processCurrentOption(this.options[this.activeOption]);
     
        this.specificationTabActive = true;
        this.template.querySelector('lightning-tabset').activeTabValue = 'spec';

        this.loading = false;
        
    }

    
    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
    handleAssetClone(event) { 
 
        //console.log('handleAssetClone');
        this.loading = true;
         
        this.quoteObject.isEdit = false;
        this.quoteObject.option = this.quoteObject.optionNum;
        this.quoteObject.isClone = true;
        
        this.showCreateInstead = false;
        this.activeOption = event.detail;
        this.quoteObject.oppId = this.opportunityId;
        this.newoption = event.detail;
        
        //keep this out for now...don't see much value
        this.processAssets(this.options[event.detail].quoteLines);
        this.processCurrentOption(this.options[event.detail]);
        
        //setTimeout( () => {//options picklist does not load fast enough
        this.specificationTabActive = true;
        this.optionsPicklistVal = event.detail;
        this.template.querySelector('lightning-tabset').activeTabValue = 'spec';
        this.loading = false;
        //}, 500);
    }

    
    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
    handleAssetDelete(event) {
        this.currentDeleteId = event.detail;
        this.displayModalDelete = true;
    }

    
    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
    displayModalDeleteToFalse(event) {
        this.displayModalDelete = false;
        this.doAssetDeleteInstead = false;
        this.deleteAssetEventSavedForModal = {};
        this.doAccessoryDeleteInstead = false;
        this.deleteAccessoryEventSavedForModal = {};
    }

    
    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
    handleDelete(event) {
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

    
    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
    deleteRelatedAccessories(assets) {
        ////console.log(assets);
        let tempAcc = JSON.parse(JSON.stringify(this.accessories));
        ////console.log(tempAcc);
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
                //this.accessories[i].accessoryHeading = 'Accessory Details';
                this.currentAccPosition = i;
            }
            this.accessories[0].isFirst = true;
        }
    }

    
    

    
    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
    removeDuplicateQuoteFromQOS(searchId) {
        for (let i = 0; i < this.quoteObjectSummary.length; i++) {
            if (this.quoteObjectSummary[i].quote.Id === searchId) {
                this.quoteObjectSummary.splice(i, 1);
                break;
            }
        }
    }

    
    
    
    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
    
    saveCustomerComments() {
        this.loading = true;
        //console.log('Start of customerCommentsSave');
        ////console.log(this.customerComments);
        ////console.log(this.opportunityId);
        saveCustomerCommentsToOpp({comments : this.customerComments, oppId : this.opportunityId})
            .then(result => {
                this.showToast('Customer comments saved!', 'Success!','success');
                this.loading = false;
            }).catch(error => {
            this.showToast('An error occurred trying to save customer comments.', JSON.stringify(error), 'error');
            this.loading = false;
        });
    }

    
    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
    quotesHaveDifference(quoteObject1, quoteObject2) {
        if (quoteObject1.quoteLines.length !== quoteObject2.quoteLines.length) {
            return true;
        }
        if ((quoteObject1.quote.Advance_Payments__c !== quoteObject2.quote.Advance_Payments__c) ||
            (quoteObject1.quote.Payment_Timing__c !== quoteObject2.quote.Payment_Timing__c)) {
            return true;
        }
        for (let i = 0; i < quoteObject1.quoteLines.length; i++) {
            let quote1 = quoteObject1.quoteLines[i];
            let quote2;
            let isFound = false;
            for (let j = 0; j < quoteObject2.quoteLines.length; j++) {
                if (quote1.Id === quoteObject2.quoteLines[j].Id) {
                    quote2 = quoteObject2.quoteLines[j];
                    isFound = true;
                    break;
                }
            }
            if (!isFound) {
                ////console.log('Truth Exit 1');
                return true;
            }
            //Make__c,Make_Id__c,Asset_Type_ITA_Class__c, Asset_Type_ITA_Class_Id__c,Model__c, Model_Id__c, Mast_Type__c,
            if ((quote1.Number_of_Units__c !== quote2.Number_of_Units__c) ||
                (quote1.Base_Unit_Sales_Price__c !== quote2.Base_Unit_Sales_Price__c) ||
                (quote1.Annual_Hours__c !== quote2.Annual_Hours__c) ||
                (quote1.Operating_Environment__c !== quote2.Operating_Environment__c) ||
                (quote1.Make__c !== quote2.Make__c) ||
                (quote1.Make_Id__c !== quote2.Make_Id__c) ||
                (quote1.Asset_Type_ITA_Class__c !== quote2.Asset_Type_ITA_Class__c) ||
                (quote1.Asset_Type_ITA_Class_Id__c !== quote2.Asset_Type_ITA_Class_Id__c) ||
                (quote1.Model__c !== quote2.Model__c) ||
                (quote1.Model_Id__c !== quote2.Model_Id__c) ||
                (quote1.Mast_Type__c !== quote2.Mast_Type__c)) {
                ////console.log('Truth Exit 2.1.1');
                return true;
            }
            if ((quote1.financeType !== quote2.financeType) ||
                (quote1.finance_term !== quote2.finance_term) ||
                (quote1.rateType !== quote2.rateType)) {
                ////console.log('Truth Exit 3.1');
                return true;
            }
        }
        return false;
    }

    
    
    
    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
    addOptionSummaries(setCurrentOption) {

        //console.log('add option summaries');
        this.loading = true;

        if (this.pricingApiCallCount !== 0) {
            this.pricingApiCallCount--;
        }
        if ((this.pricingApiCallCount !== 0) && setCurrentOption) {
            return;
        }
        this.addPricingDataToLoadedQuotes();
       
        for (let i = 0; i < this.quoteObjectSummary.length; i++) {
            for (let j = 0; j < this.options.length; j++) {
                if (this.quoteObjectSummary[i].quote.Id === this.options[j].quote.Id) {
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
                this.processAssets(this.options[this.aprocessCurrentOptionctiveOption].quoteLines);
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
        this.loading = false;
        setTimeout( () => {createQuote
            if (this.optionsPicklistVal === 0) {
                this.optionsPicklistVal = this.optionsPicklistVal.toString();
            }
            this.options = JSON.parse(JSON.stringify(this.options));
            
        }, 1);
    }
    
    
    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
    handleChildSave(event){
         
        //console.log('**********parent got the word' + JSON.stringify(event.detail)  + this.loading);
        
        //this.currentTab = 'proposal';
        
        //this.template.querySelector('lightning-tabset').activeTabValue = 'proposal';
        /*
        this.quoteObject = event.detail.quote;
        this.hasQuotes = true;
        this.oppid = event.detail.quote.oppId;
        this.optionNum = this.quoteObject.optionNum;
        this.option = this.quoteObject.optionNum;
        this.opportunityId = this.oppid;
        this.assets = this.quoteObject.assests;

        //this.connectedCallback();
        */
        //console.log ('transferring now');
         
        //console.log('received ' + event.detail.oppid);

        this.oppid = event.detail.oppid;

        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: window.location.origin + '/dllondemand/s/quotetestpage?oppid=' + event.detail.oppid
            }
        });
        /*
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'quotetestpage',
                oppid:  'dog1'
            }
        });
        */
        


        
    }

    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
    handleChildCancel(event){

        //console.log('in parent handle child cancel');

        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: window.location.origin + '/dllondemand/s/quotetestpage?oppid=' +this.oppid
            }
        });

    }

    
    

    
    
    
    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
    deleteQuote(passingParam) {
        deleteQuoteOption({quoteOptionId: passingParam})
            .then(result => {
                this.showToast('Quote has been deleted!', 'Quote was deleted successfully', 'success');
                this.parseData(result);
                this.addOptionSummaries(false);
            })
            .catch(error => {
                //console.log(JSON.stringify(error));
                this.showToast('An error has occurred trying to delete an option.', error, 'error');
                this.loading = false;
            });
    }

    
    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
    addPricingDataToLoadedQuotes() {

        //console.log('summing up dater' + this.loading);

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

    
    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
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

    
    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
    //Process after successful result of quote save
    parseData(result) {

        //this.loading = true;

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
        for (let i = 0; i < this.options.length; i++) {
            this.options[i].optionNumber = i + 1;
            this.options[i].optionIndex = i;
            this.optionsPicklist.push({value: i.toString(), label: 'Option ' + (i + 1)});
            for (let v = 0; v < this.options[i].quoteLines.length; v++) {
                //////console.log('Sequence Id is: ' + this.options[i].quoteLines[v].Sequence_ID__c);
                this.options[i].quoteLines[v].finance_term = this.options[i].quote.Term__c;
                this.options[i].quoteLines[v].rateType = this.options[i].quote.Rate_Type__c;
                this.options[i].quoteLines[v].financeType = this.options[i].quote.Lease_Type__c;
                if (this.options[i].quoteLines[v].financeType == 'BO') { this.options[i].quoteLines[v].financeType = '$1 Buy out' }
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
        ////console.log('this is the options picklist:');
        ////console.log(this.optionsPicklist);
        if (this.optionsPicklist.length === 2) {
            let wrapperEvent2 = {value: 0};
            let wrapperEvent = {target: wrapperEvent2, skipLoadToFalse: false};
            //console.log('calling handle options 1');
            
            this.handleOptionPicklist(wrapperEvent);
            this.optionsPicklistVal = '0';
            ////console.log('Done adding first selection');
        }
        if (this.onlyValidateHeader) {
            this.hasQuotes = true;
            this.specificationTabActive = false;
            this.loading = false;
            this.showToast('Quote has been saved!', 'Quote was saved successfully', 'success');
        }
    }

    
    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
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

    
    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
    stampIsPrimaryOnSelectedOption(event) {
        if(this.customerInfoShow == false){
            // Immediate feedback
            const evt = new ShowToastEvent({
                title:      'Customer Authorization',
                message:    'In order to submit your credit application, you must confirm that at least one customer information should be there.',
                variant:    'error',
                duration:   20000
            });
            this.dispatchEvent(evt);
        } else {
            markQuoteOptionAsPrimary({'quoteId' : this.creditAppId, 'oppId': this.opportunityId})
                .then(result => {
                    // Display message  //this is retarted
                    //this.showToast('Saving', 'Continuing to credit application', 'success');

                    // Redirect to the credit application page
                    this[NavigationMixin.Navigate]({
                        type: 'standard__webPage',
                        attributes: {
                            url: '/dllondemand/s/opportunity/' + this.opportunityId 
                        }
                    });
                }).catch(error => {
                ////console.log('Error stamping Is_Primary__c');
                ////console.log(JSON.parse(JSON.stringify(error)));
                this.showToast('Quote Stamp Failure.', 'Error stamping Is_Primary__c', 'error');
            });
        }
    }

    
    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
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

    
    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
    sumOfQuoteLineBaseUnitPrice(qlarr) {
        let sum = 0;
        for (let i = 0; i < qlarr.length; i++) {
            if (qlarr[i].Base_Unit_Sales_Price__c) {
                sum += parseFloat(qlarr[i].Base_Unit_Sales_Price__c);
            }
        }
        return sum;
    }

    
    /***************************************************************************************************************
    *  this loads the summary information page on the right
    ***************************************************************************************************************/
    //Process response into front end implementation
    processCurrentOption(optionWithSumData) {

         
        /*this.nickname = option.nickname;
        this.location = option.location;
        this.salesRep = option.salesRep;
        this.program = option.program;
        this.assetTypeQuote = option.assetTypeQuote;
        this.userSite = option.userSite;*/

        ////console.log('CurrentOption 0');

        let option = optionWithSumData.quote;

        ////console.log('CurrentOption 0.1');

        let baseUnitSum;
        let totalPaymentSum;
        let interestRateSum;
        let totalResidualSum;
        ////console.log('optionWithSumData');
        ////console.log(JSON.parse(JSON.stringify(optionWithSumData)));
        if (optionWithSumData.sumData && optionWithSumData.sumData[0]) {
            ////console.log('CurrentOption 1.1');
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
            ////console.log('CurrentOption 1.2');
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
            ////console.log('CurrentOption 1.3');
            if (optionWithSumData.sumData[0].interestRate) {
                interestRateSum = optionWithSumData.sumData[0].interestRate;
            } else {
                interestRateSum = 'Data Not Found';
            }
        } else if (option) {
            ////console.log('CurrentOption 1.1');
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
            ////console.log('CurrentOption 1.2');
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
            ////console.log('CurrentOption 1.3');
            if (option.Interest__c) {
                interestRateSum = (parseFloat(option.Interest__c)).toFixed(2) + '%';
            } else {
                interestRateSum = 'Data Not Found';
            }
        } else {
            baseUnitSum = 'Data Not Found';
        }

        ////console.log('CurrentOption 1');

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
        //////console.log('Past Summary Assignment');
        //////console.log(JSON.parse(JSON.stringify(optionWithSumData.sumData)));

        ////console.log('CurrentOption 2');

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
        ////console.log('CurrentOption 3');
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
        ////console.log('Retrieved data: ');
        ////console.log(JSON.parse(JSON.stringify(this.quoteObject)));
    }

    
    /***************************************************************************************************************
    *  populate asset data for display
    ***************************************************************************************************************/
    processAssets(assets) {
        //console.log('assets_processassets ' +JSON.stringify(assets) );
        //this.loading = true;
        let currentDate = new Date();
        let time = currentDate.getHours() + ":" + currentDate.getMinutes() + ":" + currentDate.getSeconds()+ 
            ":" + currentDate.getMilliseconds();  
        //console.log(time);
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
        //this.accessories = JSON.parse(JSON.stringify(this.accessories));
        //console.log(this.assets + ' '  );
        let currentDate1 = new Date();
        let time1 = currentDate1.getHours() + ":" + currentDate1.getMinutes() + ":" + currentDate1.getSeconds() + 
            currentDate1.getMilliseconds(); 
        //console.log(time1);
        //
    }

    
    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
    handleProposalToggleForQuote(event) {


        //console.log('set propostal for quote' + event.detail);

        this.loading = true;
        if (this.proposalIdsIncluded.includes(event.detail)) {
            this.proposalIdsIncluded.splice(this.proposalIdsIncluded.indexOf(event.detail), 1);
            setProposalForQuote({'quoteId':event.detail, 'trueOrFalse':'false'})
                .then(result => {
                    this.showToast('Success!', 'Quote removed from proposal.', 'success');
                    this.loading = false;
                })
                .catch(error => {
                    this.loading = false;
                    ////console.log(JSON.parse(JSON.stringify(error)));
                    this.showToast( 'An error has occurred removing this Quote from the proposal', JSON.stringify(error), 'error');
                });
        } else {
            this.proposalIdsIncluded.push(event.detail);
            setProposalForQuote({'quoteId':event.detail, 'trueOrFalse':'true'})
                .then(result => {
                    this.showToast('Success!', 'Quote added to proposal.', 'success');
                    this.loading = false;
                })
                .catch(error => {
                    this.loading = false;
                    ////console.log(JSON.parse(JSON.stringify(error)));
                    this.showToast( 'An error has occurred adding this Quote to the proposal', JSON.stringify(error), 'error');
                });
        }

        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: window.location.origin + '/dllondemand/s/quotetestpage?oppid=' + this.oppid
            }
        });
    }

    
    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
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

    
    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
    handleDealerProposal(event) {
        this.CustomerProposal = event.target.value;
        //console.log('inside cust this.oppid=>' + this.opportunityId);
        let baseUrl = this.getBaseUrl();
        getSmartCommDoc({
            batchConfigResId: 990380852,
            opportunityId: this.opportunityId,
            proposalType: 'DealerProposal'
        }).then(result => {
            if (result) {
                //console.log('success' + JSON.stringify(result));
                this.docID = result;
                this.finalurl = baseUrl + 'sfc/servlet.shepherd/document/download/' + this.docID + '?operationContext=S1';
                this[NavigationMixin.Navigate]({
                    type: 'standard__webPage',
                    attributes: {
                        url: this.finalurl
                    }
                }, false);
            }
            else{
                 this.showToast( 'An error has occurred generating document!', '', 'error');
            }

        }).catch(error => {
            this.error = error;
            this.showToast( 'An error has occurred generating document!', JSON.stringify(error), 'error');
            ////console.log(this.error);
            // this.loader = false;
        })
    }

    
    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
    handleCustomerProposal(event) {
        this.CustomerProposal = event.target.value;
        ////console.log('inside cust this.oppid=>' + this.opportunityId);
        let baseUrl = this.getBaseUrl();
        getSmartCommDoc({
            batchConfigResId: 990380852,
            opportunityId: this.opportunityId,
            proposalType: 'CustomerProposal'
        }).then(result => {
            if (result) {
                ////console.log('success' + JSON.stringify(result));
                this.docID = result;
                this.finalurl = baseUrl + 'sfc/servlet.shepherd/document/download/' + this.docID + '?operationContext=S1';
                this[NavigationMixin.Navigate]({
                    type: 'standard__webPage',
                    attributes: {
                        url: this.finalurl
                    }
                }, false);
            }
            else{
                 this.showToast( 'An error has occurred generating document!', JSON.stringify(result), 'error');
            }

        }).catch(error => {
            this.error = error;
            this.showToast( 'An error has occurred generating document!','', 'error');
            ////console.log(this.error);
            // this.loader = false;
        })
    }
    //Proposal Document -Geetha - end
    
 
    /***************************************************************************************************************
    *  
    ***************************************************************************************************************/
    handleCustomerInfoShow(event) {
        ////console.log('handle customer info show' + 'event.detail:' + event.detail + ' oppid:' + this.opportunityId);
        this.customerInfoShow=event.detail;

    }

}