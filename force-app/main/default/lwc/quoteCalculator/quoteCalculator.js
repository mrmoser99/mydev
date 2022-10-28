import { LightningElement, track, api } from 'lwc';
import Id from '@salesforce/user/Id';
import {reduceErrors,showPopUpNotification, constants,quoteStatuses,itadLevels,screenNamesEN,frequencyTranslated,
    interestTranslated, disableFieldStages,frequency, offerRVType } from 'c/ldsUtils';
import getOfferDetails from '@salesforce/apex/QuoteSetupController.getOfferDetails';
import doSaveQuoteDetail from '@salesforce/apex/QuoteSetupController.doSaveQuoteDetail';
import getQuoteDetailsOnChange from '@salesforce/apex/QuoteSetupController.getQuoteDetailsOnChange';
import getOfferDetailsOnNewVersion from '@salesforce/apex/QuoteSetupController.getOfferDetailsOnNewVersion';
import doCopyQuoteDetails from '@salesforce/apex/QuoteSetupController.doCopyQuoteDetails';
import sendCalloutToCalculationApi from '@salesforce/apex/RESTCalloutHelper.sendCalloutToCalculationApi';
import updateDealAndSaveCustomer from '@salesforce/apex/CustomerSetupController.saveAccountAndUpdateDeal';
import sendSubmitAppRequest from '@salesforce/apex/RESTCalloutHelper.makeSubmitAppRequest';
import sendCreditAssessmentRequest from '@salesforce/apex/RESTCalloutHelper.makeCreditAssessmentRequest';
import updateQuoteStatus from '@salesforce/apex/CustomerSetupController.updateQuoteStatus';
import getRateInfo from '@salesforce/apex/QuoteSetupController.getRateDetails'; 
import getMarginMatrixValue from '@salesforce/apex/QuoteSetupController.getMarginMatrixValue'; 
import createCont_Quote from '@salesforce/apex/ContractGenerationController.createCont_Quote';
import genSmartCommDoc from '@salesforce/apex/ContractGenerationController.genSmartCommDoc';
import getUserInfo from '@salesforce/apex/GenericUtilityClass.getUserInfoById';
import getRVandInsuranceValues from '@salesforce/apex/QuoteSetupController.getRVandInsuranceValues';

const MAX_UNITS = 9999;
const MAX_UNIT_PRICE = 999999999;

export default class QuoteCalculator extends LightningElement {
    
    /**Variables declaration Start*/
    labels = constants;
    quoteStatuses = quoteStatuses;
    screenNamesEN = screenNamesEN;
    itadLevels = itadLevels;
    frequencyTranslated = frequencyTranslated;
    interestTranslated = interestTranslated;
    disableFieldStages = disableFieldStages;
    frequency = frequency;
    offerRVType = offerRVType;

    offerShowAddDelButton = false; //toggle add & delete button in lease table
    productShowAddDelButton = true;  //toggle add & delete button in product table
    serviceShowAddDelButton = false;  //toggle add & delete button in service table
    @track offerData = [];
    @track leasegridColumnMeta;
    @track data =[]; //product data
    @track servicedata = [];
    @track offercurrency;
    @track totalFinanceAmount =0;
    @track insurancePerFrqncy=0;
    @track finalRentalVal = 0;
    
    @track totalAccServ = 0;
    stages = [this.labels.Calculation,this.labels.Customer,this.labels.Documents,this.labels.E_Sign,this.labels.Review];
    @track quoteCreationLst;
    changeOffrData = {};
    @track changeProdData = [];
    changeServdata = [];
    @track isLoading = false;
    @track opptyName='';
    @track quoteId = '';
    @track selCusScreen =false;
    @track selCalculationScreen =true;
    @track selDocsScreen = false;
    @track selEsignScreen = false;
    @track selReviewScreen = false;
    noProductDataOnTable = false;
    noServiceDataonTable = false;
    defTerm ;
    @track restQtnameLst = [];
    @track latestQuoteName = '';
    isNewVersion = false;
    @track totalPricewithoutCrncy;
    @track curntQuoteStage = this.quoteStatuses.Calculation; //quote stage
    @track currentScreen = this.quoteStatuses.Calculation;
    quotelineIdLst = []; //used for deletion
    updateQuoteLineIdLst = [];
    offerStr = '';
    @track flagIndicatingDataHasBeenLoadedInVariables = false;
    oppIdfromUrl = '';
    userLocale = ''; //hold the current user locale
    blurImgHeightNum = 55;
    termFromUrl = '';
    showCreditCheck = false;
    isOfferParametersChanged = false; //to check if term was changed by user
    showSpinnerOnFooter = false; //to show spinner on footer on change of unit and unitprice
    timeOutIdValue; // The ID value returned by setTimeout() is used as the parameter for the clearTimeout() method.
    CALLOUT_DELAY = 2000; // Wait for 1 second after user stops typing then, perform callout
    baseRate = '';
    customerData;
    submitAppRequest = '';
    quoteAmountRateDetails = {};
    defaultPaymentTiming = '';
    modalTitle = this.labels.Assessment_in_progress;
    modalSubtitle = this.labels.Credit_Assessment_Popup_Msg;
    isAllValuePresent = true;
    isAllValueCorrect = true;
    financeAmountFromURL = 0;
    partnerName = '';
    partnerEmail = '';
    dealDetails = [];
    isOppIdFromUrl = false;
    isTermFromUrl = false;
    channelName = '/event/Quote_Status_Update__e';
    hideServiceSection = false;
    paramsForCalculation;
    @track opportunityId = '';
    @track disableContGenFields = false;
    validTo;
    validFrom;
    @track primaryProduct;
    @track isDocumentQstnExist;
    @track enableSelectCustomerButton;
    isItadChekdOnOffer = false;
    @track enableAssessmentButton = false;
    showSyncedQuote = false;
    disabledDueToUnavailibleProduct = false;
    disabledCalculationParams;
    @track finalSmartDocCount=0;
    downpayment; 
    isdownpayment = false;
    isTermRange;
    selectableTermValues;    
    calculationCalloutCounter=0;
   
    // variables for Calculation Params table start
    @api selectedUserId;
    currentUserId = Id;
    behaveOnUserId;
    isInternalDLLMember;
    showCalculationDetails;
    @track calculationParams;
    calculationTableClasses;
    rateName;
    costOfFunds;
    @api oppRecordId;
    calculationParamsFromExistingQuote;
    // variables for Calculation Params table end

    viewRentPerMonth;
    totalPurchaseOptionAmount;
    @api partnerInfo;
    accountRegionCode; //hold the Account region Code

    /**Variables declaration End*/

    /*Offer Column*/
    @track leasecols = [
        { Translatedlabel : this.labels.deal_Page_Offer,label: "Offer", fieldName : "Offer__c", display : "lookup", source : "apex", schema : "", icon : "action:call", objKey : "Offer__c", editable: true, required: false, paddingCss:'padding-right: 0.5%;'},
        { Translatedlabel : this.labels.deal_Page_Frequency, label: "Frequency",fieldName : "frequency", display : "picklist", source : "array", schema : "", icon : "", "objKey" : "", editable: true, required: false, paddingCss:'padding-right: 0.5%;'}, 
        { Translatedlabel : this.labels.deal_Page_Term,label: "Term", fieldName : "term", display : "picklist", source : "array", schema : "", icon : "", "objKey" : "", editable: true, required: false, paddingCss:'padding-right: 0.5%;' }, 
        { Translatedlabel : this.labels.deal_Page_Interest,label: "Interest", fieldName : "interest", display : "picklist", source : "array", schema : "", icon : "", "objKey" : "", editable: true, required: false,paddingCss:'padding-right: 0.5%;'},
        { Translatedlabel : this.labels.Purchase_Option, label: this.offerRVType.Purchase_Option, fieldName : "purchaseOption", display : "picklist", source : "array", editable: true, required: false, paddingCss:'padding-right: 0.5%;', isHidden: true},
        { Translatedlabel : this.labels.deal_Page_ITAD, label: "ITAD",fieldName : "itadlevel", display : "picklist", source : "array", schema : "", icon : "", "objKey" : "", editable: true, required: false, paddingCss:'padding-right: 0.5%;', isHidden: true},
    ];

    /*Product Column*/
    @track cols = [
        { Translatedlabel : this.labels.deal_Page_product, label: "Product", fieldName : "Product", display : "lookup", source : "apex", schema : "", icon : "action:call", objKey : "Product2", editable: true, required: false, paddingCss:'padding-right: 0.5%; width:16rem;'},
        { Translatedlabel : this.labels.deal_Page_Specification, label: "Specification",  fieldName : "specification", display : "lwc.input", source : "text", schema : "" , icon : "", objKey : "", editable: true, required: false, paddingCss:'padding-right: 0.5%; width:33rem;'}, 
        { Translatedlabel : this.labels.deal_Page_Units, label: "Units",  fieldName : "quantity", display : "lwc.input", source : "number", schema : "" , icon : "", objKey : "", editable: true, required: false, paddingCss:'padding-right: 0.5%; width:6rem;'}, 
        { Translatedlabel : this.labels.deal_Page_Unit_Price, label: "Unit Price", fieldName : "unitprice", display : "lwc.input", source : "number", schema : "" , icon : "", objKey : "", editable: true, required: false, paddingCss:'padding-right: 0.5%; width:6rem;'}, 
        { Translatedlabel : this.labels.deal_Page_Total_Price, label: "Total Price", fieldName : "totalprice", display : "lwc.output", source : "number", schema : "" , icon : "", objKey : "", editable: false, required: false, paddingCss:'width:5.5rem;'},
        { Translatedlabel : this.labels.Insurance, label: "Insurance", fieldName : "insuranceAmount", display : "lwc.input", source : "number", editable: true, paddingCss:'padding-right: 0.5%; width:6rem;', isHidden: true},
        { Translatedlabel : this.labels.Purchase_Option_Amount, label: "Purchase Option", fieldName : "residualValue", display : "lwc.input", source : "number", editable: true, paddingCss:'padding-right: 0.5%; width:6rem;', isHidden: true},
        
    ];

    /** Maintenance Columns */
    serviceCols = [
        { Translatedlabel : this.labels.Type,label: "Type", fieldName : "Product", display : "lookup", source : "apex", schema : "", icon : "action:call", objKey : "Product2", editable: true, required: false, paddingCss:'padding-right: 0.5%; width:16rem;'},
        { Translatedlabel : this.labels.Quantity,label: "Quantity", fieldName : "quantity", display : "lwc.input", source : "number", schema : "" , icon : "", objKey : "", editable: true, required: false, paddingCss:'padding-right: 0.5%; width:7rem;'}, 
        { Translatedlabel : this.labels.Amount_Monthly,label: "Amount (Monthly)", fieldName : "unitprice", display : "lwc.input", source : "number", schema : "" , icon : "", objKey : "", editable: true, required: false, paddingCss:'padding-right: 0.5%; width:6rem;'}, 		
        { Translatedlabel : "",label: "", fieldName : "col", display : "lwc.output", source : "number", schema : "" , icon : "", objKey : "", editable: true, required: false, paddingCss:'padding-left: 0.5%;padding-right: 0.5%; width:28rem;'},
        { Translatedlabel : this.labels.Total_Amount_Monthly,label: "Total Amount (Monthly)", fieldName : "totalprice", display : "lwc.output", source : "number", schema : "" , icon : "", objKey : "", editable: true, required: false, paddingCss:'width:5.5rem;'},   
    ]

    connectedCallback(){
        document.title = 'Deal';
        window.addEventListener('beforeunload', this.beforeUnloadHandler.bind(this));
        this.isLoading = true;
        let newURL = new URL(window.location.href).searchParams;
        this.oppIdfromUrl = newURL.get('oppId'); //get the oppid from URL

        // if component is opended from record page
        if (this.oppRecordId != null) {
            this.oppIdfromUrl = this.oppRecordId;
        }

        this.enableSelectCustomerButton = (this.oppIdfromUrl === null) ? false : true;
        this.termFromUrl = newURL.get('term');  //get the term from URL
        this.financeAmountFromURL = newURL.get('financeAmount'); //get financeAmount from URL
        this.isOppIdFromUrl = this.oppIdfromUrl != null && this.oppIdfromUrl != '' ? true : false;
        this.isTermFromUrl = this.termFromUrl != null && this.termFromUrl != '' ? true : false;

        // if quote is opened to view/edit on parther behave, then behaveOnUserId = OwnerId
        this.behaveOnUserId = (this.selectedUserId) ? this.selectedUserId : this.currentUserId;

        this.getUserInfoAndOfferDetails();
    }

    /* Get user info and ogger delails for Calculation screen */
    getUserInfoAndOfferDetails() {
        getUserInfo({userId: this.currentUserId})
        .then(result => {
            let userInfo = JSON.parse(result);

            // check if current user is internal dll member
            this.isInternalDLLMember = (userInfo.Profile.Name === 'Nordics Internal MVP') ? true : false;

            /* Call apex method to get the default offer details */
            this.getOfferDetails();
        })
        .catch(error => {           
            showPopUpNotification(this, reduceErrors(error), 'error');
            console.error(reduceErrors(error));
        })
    }

    /* Call apex method to get the default offer details */
    getOfferDetails() {
        getOfferDetails({
            oppIdFromUrl : this.oppIdfromUrl,
            financeAmount : Math.round(this.financeAmountFromURL),
            behaveOnUserId: this.behaveOnUserId
        })
        .then(result => {         
           
            this.refreshComp(result,false,false);  
            // check if current user is a manager
            if (this.isInternalDLLMember) {
                this.calculationTableClasses = 'calculation-tables slds-col slds-size_3-of-5';
                this.showCalculationDetails = true;
            } else {
                this.calculationTableClasses = 'calculation-tables slds-col slds-size_1-of-1';
            }         
            this.isLoading = false; 
        })
        .catch(error => {
            showPopUpNotification(this,this.labels.contact_Admin_Error,'error');
        });
    }
  
    beforeUnloadHandler(e) {
       // Cancel the event
        e.preventDefault(); // If you prevent default behavior in Mozilla Firefox prompt will always be shown
        // Chrome requires returnValue to be set
        e.returnValue = '';      
    }

    disconnectedCallback() {
        window.removeEventListener("beforeunload", this.beforeUnloadHandler);
    }

    /**Handle offer change on Quote Change */
    handleChangeOfferOnQuote(event){
        let result = event.detail;    
        this.refreshComp(result,true,false);       
    }

    /**Handle the refresh of whole table data. Forming the correct JSON structure */
    refreshComp(apexResult,onChangeOffer,onchangeQuote){
        
        this.dealDetails = apexResult.submitAddWrapper;  
        this.submitAppRequest = (this.dealDetails == undefined) ? null : this.createSubmitApplicationRequest();
        let result = apexResult;
        let termoptions;
        let frequencyoptions;
        let interstoptions;
        let value = [];
        let offerCls;
        let productCls;
        let serviceCls ;
        let defaultFreq;
        this.downpayment = 0.0;
        this.isdownpayment = false;

        if(onChangeOffer){
            this.offerData = [];
            this.data = [];
            this.servicedata = [];       
            this.opptyName = this.opptyName;
            this.quoteId = this.quoteId; //hold the quote id
            this.restQtnameLst = this.restQtnameLst;   
            this.latestQuoteName = this.latestQuoteName; 
            this.isItadChekdOnOffer = false;
            const foundItadColumn = this.leasecols.find(element => element.label == 'ITAD');
            if(foundItadColumn.isHidden === false)
                //on offer change, search if itad column is there in the offer section and remove it      
                foundItadColumn.isHidden = true;  
        }else if(onchangeQuote){
            this.offerData = [];
            this.data = [];
            this.servicedata = []; 
            this.quotelineIdLst = [];
        }      
    
        if(result){         
            this.flagIndicatingDataHasBeenLoadedInVariables = true;          
            offerCls = result['offrcls'];
            productCls = result['prdCls'];
            serviceCls = result['srvCls'];
            this.primaryProduct = result['prdCls'][0];
            this.userLocale = result.twCurrentUserLocale; //getting the current user locale
            this.accountRegionCode = result.accountRegionCode; //getting the Account regionCode
            if(this.partnerName == ''){
                this.partnerName = result.partnerName;
            }
            if(this.partnerEmail == ''){
                this.partnerEmail = result.partnerEmail;
            }
            
            if(offerCls[0]['isItadApplicable']){
                this.isItadChekdOnOffer = true;
             }
            this.curntQuoteStage = result.quoteStatus != null ? result.quoteStatus : ''; //hold the quote status
            this.isDocumentQstnExist = result.isDocumentQstnExist;
            this.validFrom = result.validFrom;
            this.validTo = result.validTo;
            this.disableContGenFields = (result.quoteStatus != null && (
                result.quoteStatus == this.quoteStatuses.PendingESign || 
                result.quoteStatus == this.quoteStatuses.PendingReview || 
                result.quoteStatus == this.quoteStatuses.BlockedDueToMultiplePG || 
                result.quoteStatus == this.quoteStatuses.PendingDocumentation || 
                result.quoteStatus == this.quoteStatuses.PendingInformation || 
                result.quoteStatus == this.quoteStatuses.DocumentsGenerated || 
                result.quoteStatus == this.quoteStatuses.ReviewCompleted || 
                result.quoteStatus == this.quoteStatuses.PendingValidation)) ? true : false;
            this.opportunityId = this.oppIdfromUrl != null ?  this.oppIdfromUrl : result.opportunityId;
            
            if(!onChangeOffer && !onchangeQuote){
                this.opptyName = result.opptyName != undefined ? result.opptyName : this.opptyName;
                this.quoteId = result.quoteid;                 
                this.oppIdfromUrl = result.newOppIdWhenQtPgDirectlyOpen == undefined ? this.oppIdfromUrl : result.newOppIdWhenQtPgDirectlyOpen; //US449018 scenario:2 [Opporty id when quote calcultion screen directly opened from create deal tab]
                if(result.restQuotes != null && result.restQuotes != ''){
                    const restQtLst = result.restQuotes.split(';');     
                    this.showSyncedQuote = true;
                    for(let i in restQtLst){  
                        const restQuoteNames = {
                            label : restQtLst[i].substring(0, restQtLst[i].indexOf('=')),
                            value : restQtLst[i].substring(0, restQtLst[i].indexOf('=')),
                            qid : restQtLst[i].substring( restQtLst[i].indexOf('=')+1,restQtLst[i].indexOf('❆')),
                            qnum : restQtLst[i].substring(restQtLst[i].indexOf('❆')+1,restQtLst[i].length)
                        }                   
                        this.restQtnameLst.push(restQuoteNames); //all the quote name detail list   
                    }                
                    const foundSyncedQuote = this.restQtnameLst.find(element => element.label.includes('★')); //always find the synced quote and open it               
                    this.latestQuoteName =  result.latestQuote;
                     
                    if (foundSyncedQuote.qid != this.quoteId) {
                        this.quoteChangeHandler(foundSyncedQuote.qid);
                        return;
                    }
                }             
                this.totalPricewithoutCrncy = result.totalFinanceVal; 
            }
            
            //create offer         
            for(let eachofr in offerCls){
                this.offercurrency = offerCls[eachofr]['defaultcurncy'] === 'EUR' ? '€ ' : offerCls[eachofr]['defaultcurncy'] === 'USD' ? '$ ' : offerCls[eachofr]['defaultcurncy'] === 'CAD' ? '$ ' : 'kr ' ;
                this.defTerm =  this.termFromUrl != null ? this.termFromUrl : offerCls[eachofr]['defaultTerm']; 
                this.offerStr = offerCls[eachofr]['offerid'];
              
                //show itad column on ui if quote has itad level
                const foundItadColumn = this.leasecols.find(element => element.label == 'ITAD');
                if(offerCls[eachofr]['itadLevel'] && foundItadColumn.isHidden === true){                    
                    foundItadColumn.isHidden = false;
                }

                const newofrobj = {
                    uid : '1',
                    Offer__c : offerCls[eachofr]['offerid'],
                    offername : offerCls[eachofr]['offerName'],
                    term : this.termFromUrl != null ? this.termFromUrl : offerCls[eachofr]['defaultTerm'], 
                    frequency : offerCls[eachofr]['defaultFreq'],
                    interest : offerCls[eachofr]['defaultInt'],
                    paymentTiming : offerCls[eachofr]['paymentTiming'] == 'In Advance' ? 'in-advance' : offerCls[eachofr]['paymentTiming'] == 'In Arrears' ? 'in-arrears' : offerCls[eachofr]['paymentTiming'],
                    curencycode : offerCls[eachofr]['defaultcurncy'] === 'EUR' ? '€' : offerCls[eachofr]['defaultcurncy'] === 'USD' ? '$' : offerCls[eachofr]['defaultcurncy'] === 'CAD' ? '$' : 'kr',
                    programId : offerCls[eachofr]['programId'],
                    applicableOfferId : offerCls[eachofr]['applicableOfferId'],
                    itadlevel : offerCls[eachofr]['itadLevel'] ? offerCls[eachofr]['itadLevel'] : '',
                    isPurchaseOptionApplicable: offerCls[eachofr]['rvType'] === this.offerRVType.Purchase_Option ? true : false, 
                    purchaseOption: (offerCls[eachofr]['rvType'] === this.offerRVType.Purchase_Option && result.appliedPR === true)
                        ? 'true' 
                        : 'false',                 
                }
                this.defaultPaymentTiming = offerCls[eachofr]['paymentTiming'] == 'In Advance' ? 'in-advance' : offerCls[eachofr]['paymentTiming'] == 'In Arrears' ? 'in-arrears' : offerCls[eachofr]['paymentTiming'];
                this.offerData.push(newofrobj); 
                //to get frequency, interest options seperated by semi-colon  
                frequencyoptions = offerCls[eachofr]['freqOptions'].split(';');
                interstoptions = offerCls[eachofr]['intOptions'].split(';');
                this.selectableTermValues = offerCls[eachofr]['termsOption'];
                this.isTermRange = offerCls[eachofr]['termRange'];
                defaultFreq = offerCls[eachofr]['defaultFreq'];
                termoptions = this.getTermRange(offerCls[eachofr]['defaultFreq'],offerCls[eachofr]['termsOption'],offerCls[eachofr]['termRange']);

                if(this.termFromUrl != null && this.termFromUrl != undefined && !termoptions.includes(this.termFromUrl)){
                     termoptions.push(this.termFromUrl); //add the term from url to the dropdown list only if it is not present in the dropdown options
                 }      
            }  

            //to get downpayment
            if(result.downpayment > 0.0){
                this.downpayment = result.downpayment;
                this.isdownpayment = true;
            }
            
            //looping over each item and pushing to the list of terms
            for(const eachterm in termoptions){
                const termobj = {
                    cellid : 'term',
                    label : termoptions[eachterm],
                    value : termoptions[eachterm]
                }
                value.push(termobj);
            }
            //looping over each item and pushing to the list of frequency
            for(const eachfreq in frequencyoptions){
                const freqobj = {
                    cellid : 'frequency',                
                    label : this.frequencyTranslated[frequencyoptions[eachfreq]],
                    value : frequencyoptions[eachfreq]
                }

                value.push(freqobj);
            }
            //looping over each item and pushing to the list of interest
            for(const eachint in interstoptions){
                const intobj = {
                    cellid : 'interest',
                    //label : interstoptions[eachint],
                    label: this.interestTranslated[interstoptions[eachint]],
                    value : interstoptions[eachint]
                }
                value.push(intobj);
            }
            
            //itad options
            let itadLevelOptions = [this.itadLevels.Data_Wiping,this.itadLevels.Reversed_Logistics,this.itadLevels.Onsite_Packaging];
            itadLevelOptions.forEach(index=>{
                let itadLabel = '';
                if(index === this.itadLevels.Data_Wiping){
                    itadLabel = this.labels.data_Wiping;
                }else if(index === this.itadLevels.Reversed_Logistics){
                    itadLabel = this.labels.reversed_Logistics;
                }else if(index === this.itadLevels.Onsite_Packaging){
                    itadLabel = this.labels.onsite_Packaging;
                }
                if(itadLabel != ''){                 
                    value.push({ cellid : 'itadlevel', label: itadLabel, value: index});
                }            
            })
            
            this.leasegridColumnMeta = value;
           
            //create products  
            let i=1;
            let hasUnavailableProductOrService = false;

            for(const eachprod in productCls){  
                if (!productCls[eachprod]['isProductAvailable'] && productCls[eachprod]['isProductAvailable'] !=null) {
                    hasUnavailableProductOrService = true;
                }
                const prodObj = {
                    uid : i,
                    Product : productCls[eachprod]['prodid'] != null && productCls[eachprod]['prodid'] != '' ?  productCls[eachprod]['prodid'] : '',
                    productname: productCls[eachprod]['prodName'] != null && productCls[eachprod]['prodName'] != '' ?  productCls[eachprod]['prodName'] : '',
                    productType: productCls[eachprod]['productType'] != null && productCls[eachprod]['productType'] != '' ?  productCls[eachprod]['productType'] : '',
                    specification : productCls[eachprod]['prodDesc'] != '' ? productCls[eachprod]['prodDesc'] : '',
                    quantity : productCls[eachprod]['quantity'] != '' ? productCls[eachprod]['quantity'] : '',
                    unitprice : productCls[eachprod]['unitprice'] != '' ? productCls[eachprod]['unitprice'] : '',
                    totalprice : productCls[eachprod]['totalprice'] != '' ? productCls[eachprod]['totalprice'] : '0',
                    curencycode : this.offercurrency,
                    operation : productCls[eachprod]['operation'],
                    quotelineid : productCls[eachprod]['quotelineid'],
                    isItadApplicable : offerCls[0]['itadLevel'] != null ?  true : false,
                    insuranceAmount: productCls[eachprod]['insuranceRate'] != null ? productCls[eachprod]['insuranceRate'] : null,
                    residualValue: productCls[eachprod]['rvRate'] != null ? productCls[eachprod]['rvRate'] : null,
                    isPurchaseOptionAvailable: productCls[eachprod]['isPurchaseOptionAvailable'] != null ? productCls[eachprod]['isPurchaseOptionAvailable'] : null,
                    isInsuranceAvailable: productCls[eachprod]['isInsuranceAvailable'] != null ? productCls[eachprod]['isInsuranceAvailable'] : null,
                    isDelBtnHide: i == 1 
                }              
                //will be used for delete purpose              
                this.quotelineIdLst.push(productCls[eachprod]['quotelineid']);   
                
               
                i++;              
                this.data.push(prodObj); 
                
            }
            //create service
            let j=1;
            for(const eachserv in serviceCls){
                if (!serviceCls[eachserv]['isProductAvailable'] && serviceCls[eachserv]['isProductAvailable'] !=null) {
                    hasUnavailableProductOrService = true;
                }
                const servObj = {
                    uid : j,
                    Product : serviceCls[eachserv]['serviceId'], 
                    productname: serviceCls[eachserv]['serviceName'], 
                    productType: serviceCls[eachserv]['productType'] != null && serviceCls[eachserv]['productType'] != '' ?  serviceCls[eachserv]['productType'] : '',
                    service:'service'+j,                     
                    quantity : serviceCls[eachserv]['quantity'] != '' ? serviceCls[eachserv]['quantity'] : '',
                    unitprice : serviceCls[eachserv]['unitprice'] != '' ? serviceCls[eachserv]['unitprice'] : '',
                    totalprice : serviceCls[eachserv]['totalprice'] != '' ? serviceCls[eachserv]['totalprice'] : '0',
                    curencycode : this.offercurrency,
                    operation : serviceCls[eachserv]['operation'], 
                    quotelineid : serviceCls[eachserv]['quotelineid'] 
                }
                //will be used for delete purpose
                this.quotelineIdLst.push(serviceCls[eachserv]['quotelineid']);
                j++;
                this.servicedata.push(servObj);                      
            }

            if (this.servicedata.length === 0 && (this.curntQuoteStage === this.quoteStatuses.Calculation ||  !this.curntQuoteStage)) {
                this.servicedata.push({
                    uid : 1,
                    Product : '', 
                    productname: '', 
                    productType: '',
                    service:'service1',                     
                    quantity : '',
                    unitprice : '',
                    totalprice : '',
                    curencycode : '',
                    operation : 'add', 
                    quotelineid : ''
                });
            }         
          
            this.totalFinanceAmount =  result.totalFinanceVal; 
            this.insurancePerFrqncy = result.insuranceAmount != undefined ? result.insuranceAmount : 0;  
            //this.finalRentalVal = this.offercurrency+' '+ result.rentalVal ;
            
            this.viewRentPerMonth = result.viewRentPerMonth;
            
            this.finalRentalVal = this.getFinalRentalValue(offerCls[0]['defaultFreq'],result.rentalVal);
            

            this.totalAccServ = result.accumulatedService != undefined ? result.accumulatedService : 0;
            this.baseRate = result.baseRate;
            
            this.handleFinalQuoteCreation(this.offerData,this.data,this.servicedata);
            this.totalFinanceAmount ;
            this.insurancePerFrqncy;

            this.checkIfCalculalationParamsAreDisabled(result);

            this.totalPurchaseOptionAmount = (this.changeOffrData.purchaseOption === 'true') 
                ? ((result.futureValue) ? result.futureValue : 0) : '0';

            if (hasUnavailableProductOrService && !this.disableFieldStages.includes(this.curntQuoteStage)) {
                this.disabledDueToUnavailibleProduct = true;
                this.showHideAddButton();
                this.template.querySelector('c-pop-up-notification-cmp').isNotificationStatic = true;
                showPopUpNotification(this,this.labels.Products_Have_Been_Changed_Create_New_Version,'info');
            } else {
                this.disabledDueToUnavailibleProduct = false;
                this.template.querySelector('c-pop-up-notification-cmp').isNotificationStatic = false;
                this.template.querySelector('c-pop-up-notification-cmp').hideNotification();
            }
        }

        // show/hide insurance if it's applicable
        this.handleInsuranceColumn(); 
        
        // show/hide purchase option if it's applicable
        this.handlePurchaseOptionColumn(); 

        // set values for Calculation Params table for quote if current user is internal dll member
        if(this.isInternalDLLMember) {
            this.calculateCalculationParamsFromExistingQuote(result);
        }
        
        this.selectScreen(); // select screen according to the current quote status
       
        if (this.disabledDueToUnavailibleProduct || result.infoMessage != null) {
            setTimeout(this.showCalculationScreen.bind(this), 100);
        }
    }

    /**Handle offer parameter change */
    handleOfferParamsChange(termval){       
        this.isOfferParametersChanged = false;
        if(termval != 'null'){
            this.isOfferParametersChanged = true;
            this.defTerm = termval;
        }       
    }

    /*to show total price of product on the footer*/
    handleTotalPrice(event){       
        let finalPrc= event.detail;
        finalPrc = String(finalPrc);
        this.totalPricewithoutCrncy = finalPrc;       
    }

    /**Method to form term range if Include_term_range_value is true */
    getTermRange(frequency, termvalues,termRange){
        let tRange = [];
        let tList= [];
        let minTerm = 0;
        let maxTerm = 0;
        let getFrequency = 0;

        if(termRange){
            tList = termvalues.split(';');
            minTerm = tList[0];
            maxTerm = tList[tList.length - 1];
            getFrequency = this.getPaymentFrequencyInt(frequency);

            tRange.push(String(minTerm));
            for(let i = parseInt(minTerm); i < parseInt(maxTerm);){
                i+=getFrequency;
                tRange.push(String(i));
            }
            return tRange;
        }
        else{
            tList = termvalues.split(';');
            return tList;
        }
    }

    /*Handle term creation list event fired when user changes frequency value*/
    handleTermRangeFrequency(currentVal){
        let termoptions;
        if(currentVal == 'Quarterly' || currentVal == 'Semi-Annually' ||
           currentVal == 'Annually' || currentVal == 'Monthly'){

            termoptions = this.getTermRange(currentVal,this.selectableTermValues,this.isTermRange);

            this.leasegridColumnMeta = this.leasegridColumnMeta.filter((element) => {
                return element.cellid != 'term';
            });

            for(const eachterm in termoptions){
                const termobj = {
                    cellid : 'term',
                    label : termoptions[eachterm],
                    value : termoptions[eachterm]
                }
                this.leasegridColumnMeta.push(termobj);
            }
        }
    }

    /*Handle quote creation list event fired when user changes any field value*/
    handleQuoteCreation(event){
        // disable select customer button
        this.enableSelectCustomerButton = false;
        this.handleOfferParamsChange(event.detail.currentval);
        this.updateQuoteLineIdLst.push(event.detail.oldprodid);

        //when there is change in frequency then handleTermRangeFrequency method is called.
        this.handleTermRangeFrequency(event.detail.currentval);
        
        //when user deletes all rows in product or service
        if(Object.keys(event.detail.value).length == 0 && event.detail.deletebtn == 'Products'){
            this.noProductDataOnTable = true;
            this.changeProdData = event.detail.value;
        }
        if(Object.keys(event.detail.value).length == 0 && event.detail.deletebtn == 'Service'){
            this.noServiceDataonTable = true;
            this.changeServdata = event.detail.value;
        }
        if(event.detail.value[0]?.term){
            this.changeOffrData = event.detail.value[0];  
            this.changeOffrData['paymentTiming'] = this.defaultPaymentTiming; 
        }else if(event.detail.value[0]?.hasOwnProperty('specification')){
            this.changeProdData = event.detail.value;           
        }else{       
            this.changeServdata = event.detail.value;
        }
        
        /*call apex to get the base rate depending on user changes*/
        this.getRateInfo(this.changeOffrData.Offer__c, this.changeOffrData.term, this.changeOffrData.frequency, this.changeOffrData.interest);
      
        //if any product has itad product linked to it, then show the itad column.
        const foundItadAppilableProd = this.changeProdData.find(element => element.isItadApplicable);
        const foundItadColumn = this.leasecols.find(element => element.label == 'ITAD');
        if(foundItadAppilableProd != undefined && this.isItadChekdOnOffer && foundItadColumn.isHidden === true){
            foundItadColumn.isHidden = false;
        }else if(foundItadColumn.isHidden === false && foundItadAppilableProd == undefined){
            //if not itad product found, then search if itad column is there in the offer section and remove it      
            foundItadColumn.isHidden = true;
        }

        this.handleInsuranceColumn();
        this.handleRVColumnForProducts();
        
        const offerRows = this.changeOffrData;
        const allProdRows = this.changeProdData;
        const serviceRows = this.changeServdata;
        

        //pass all the row values for callout. if user types before CALLOUT_DELAY, cancel the callout and again wait for CALLOUT_DELAY.
        if(this.timeOutIdValue != undefined && this.timeOutIdValue){
            clearTimeout(this.timeOutIdValue);
        }
        this.timeOutIdValue = setTimeout(() => {
            this.handleCalloutToCalculationApi(offerRows,allProdRows,serviceRows)
            }, this.CALLOUT_DELAY);
    }

    /*call apex to get the base rate depending on user changes*/
    getRateInfo(offerId, term, frequency, interest) {
        getRateInfo({ 
            offerId : offerId,
            term : term,
            frequency : frequency,
            interest : interest,
         })
        .then(result => {
            let rateInfo = JSON.parse(result);
            this.baseRate = rateInfo.rateValue;

            if (this.isInternalDLLMember) {
                this.rateName = rateInfo.rateName;    
                this.costOfFunds = rateInfo.costOfFunds; 
                this.calculationParams.rate['Reference Rate'] = this.rateName;
                this.calculationParams.rate['Rate'] = this.baseRate;
                this.calculationParams.rate['Cost of Funds'] = this.costOfFunds;
            }
        })
        .catch(error => {
            showPopUpNotification(
                this,
                reduceErrors(error), 
                'error'
            );
        });
    }

    /**Handle the Quote creation */
    handleFinalQuoteCreation(offerdata,productdata,servicedata){
        this.changeOffrData = offerdata[0];
        this.changeProdData = productdata;
        this.changeServdata = servicedata;     
    }
    /**method to find if a value is valid or not */
    isNullOrZeroOrUndefined(value) {
        return value == null || value == undefined || value == 0 || value == '';
    }

    /**
     * Create the calcualtion request JSON structure
     * param offerRowValues 
     */
    createCalculationRequest(offerRowValues){
        let paramsForCalculation = {
            calculate : 'payments',
            numberOfMonths : offerRowValues.term,
            paymentFrequency : offerRowValues.frequency,
            paymentTiming : offerRowValues.paymentTiming,
            programId: offerRowValues.programId,
            financialProductId: offerRowValues.applicableOfferId,
            interest: offerRowValues.interest,
            itadLevel : offerRowValues.itadlevel,
            assets : [],
            maintenance: [],
            isInsuranceApplicable: this.isInternalDLLMember,
            isPurchaseOptionApplicable: this.changeOffrData.purchaseOption === 'true' ? true : false,
        }; 
        return paramsForCalculation;
    }

    /**
     * Purpose: to perform the callout to Calcuation api by calling the apex method
     * Params: offerRowValues: offer details, allQuoteLineRowValues: quote line details[product & services]
     */
    handleCalloutToCalculationApi(offerRowValues,allQuoteLineRowValues,serviceRows){
        this.isAllValuePresent = true;
        this.isAllValueCorrect = true;
      
        //check if all row has values: product, quantity, unit price
        if(offerRowValues && allQuoteLineRowValues){
            for(const eachIndex in allQuoteLineRowValues){ 
                if(allQuoteLineRowValues[eachIndex]['Product'] == '' || allQuoteLineRowValues[eachIndex]['quantity'] == '' || allQuoteLineRowValues[eachIndex]['unitprice'] == ''){
                    this.isAllValuePresent = false;    
                    break;               
                } else if (allQuoteLineRowValues[eachIndex]['quantity'] > MAX_UNITS || allQuoteLineRowValues[eachIndex]['unitprice'] > MAX_UNIT_PRICE) {
                    this.isAllValueCorrect = false;
                    break;
                }else if(this.accountRegionCode ===  'SE' && Number.parseInt(allQuoteLineRowValues[eachIndex]['totalprice']) < 15 ){
                    showPopUpNotification(
                        this,
                        this.labels.Error_Minimum_Price, 
                        'error'
                    );
                    this.isAllValueCorrect = false;
                    break;
                }
            
            } 
        }
      
        let services = [];
        if (serviceRows) {
            for(const eachIndex in serviceRows){ 
                if (serviceRows[eachIndex]['Product'] === '' && serviceRows[eachIndex]['quantity'] === '' && serviceRows[eachIndex]['unitprice'] === '') {	
                } else if (serviceRows[eachIndex]['Product'] === '' || serviceRows[eachIndex]['quantity'] === '' || serviceRows[eachIndex]['unitprice'] === '') {
                    this.isAllValueCorrect = false;   
                    break;        
                } else if (serviceRows[eachIndex]['quantity'] > MAX_UNITS || serviceRows[eachIndex]['unitprice'] > MAX_UNIT_PRICE) {
                    this.isAllValueCorrect = false;
                    break;
                } else {
                    services.push(serviceRows[eachIndex]);
                }
            } 
        }
       
        //if all value is present then only do the callout to Calculation API
        if(this.isAllValuePresent && this.isAllValueCorrect){
            let paramsForCalculation = this.createCalculationRequest(offerRowValues);
            allQuoteLineRowValues.forEach(quoteLineItem => {
                let asset = {
                    productName : quoteLineItem.productname,
                    productType : quoteLineItem.productType,
                    quantity : quoteLineItem.quantity,
                    price : quoteLineItem.unitprice,
                    insuranceAmount : quoteLineItem.insuranceAmount,
                    residualValueAmount : quoteLineItem.residualValue,
                };
                paramsForCalculation.assets.push(asset);
            });

            services.forEach(serviceItem => {
                let service = {
                    productName : serviceItem.productname,
                    productType : serviceItem.productType,
                    quantity : serviceItem.quantity,
                    price : serviceItem.unitprice
                }
                paramsForCalculation.maintenance.push(service);
            }); 

            this.showSpinnerOnFooter = true;
            this.paramsForCalculation = paramsForCalculation;

           // console.log('calculation params:' + JSON.stringify(paramsForCalculation));
            this.calculationCalloutCounter = this.calculationCalloutCounter + 1;
            sendCalloutToCalculationApi({
                paramsForCalculation : JSON.stringify(paramsForCalculation),
                saveLogsAsync: true
            })
            .then(result => {   
                if (result.errorMessage != '') {
                    showPopUpNotification(this,result['errorMessage'],'error');
                    this.enableSelectCustomerButton = false //update to false
                } else {
                  
                    //show the response if there is no error from calculation API
                    
                    this.totalFinanceAmount = Math.round(result.financeAmount); //financial amount
                    this.finalRentalVal = this.getFinalRentalValue(result.paymentFrequency,result.rentalAmount);
                 //   console.log('Final Rental Value:'+this.finalRentalVal);
                    this.quoteAmountRateDetails = {
                        financeAmount : Math.round(result.financeAmount),
                        rentalAmount : Math.round(result.rentalAmount),
                        nominalInterestRate : result.nominalInterestRate, //response.financeCalculation.rates.nominalInterestRate
                        futureValue: result.futureValue,
                    }

                    this.totalPurchaseOptionAmount = (this.changeOffrData.purchaseOption === 'true') 
                        ? result.futureValue : '0';

                    //udpating the product object with rv and insurane
                    this.changeProdData.forEach(prodItem => {     
                         result.assets.forEach(assetItem => {                          
                            if(prodItem.productname == assetItem.productName && prodItem.quantity == assetItem.quantity && prodItem.unitprice == assetItem.salePrice){
                                prodItem.residualValue = (this.changeOffrData.isPurchaseOptionApplicable === true && this.changeOffrData.purchaseOption === 'false') 
                                    ? null
                                    : assetItem.residualValue;
                                prodItem.insuranceAmount = assetItem.insuranceAmount;
                                prodItem.assetModelId = assetItem.assetModelId;
                            }
                        });
                        //updating the product object with per asset finance Amount and rental Amount
                        result.assetCalculations.forEach(assetCalculationItem => {                          
                            if(prodItem.productname == assetCalculationItem.productName && prodItem.quantity == assetCalculationItem.quantity && prodItem.unitprice == assetCalculationItem.salePrice){
                                prodItem.financeAmount = assetCalculationItem.financeAmount;
                                prodItem.periodicAmount = assetCalculationItem.periodicAmount;
                            }
                        });
                    });

                    //updating offer object with insurance payment
                    this.changeOffrData.insurancePayments = result.insurancePayments;
                    this.insurancePerFrqncy =  result.insurancePayments;
                    
                    let maintAmount = 0;
                    this.totalAccServ = 0;
                    //updating service object with maintance amount
                    this.changeServdata.forEach(serviceItem => {  
                        result.maintenance.forEach(maintItem => {   
                            if(serviceItem.productname == maintItem.id){
                                serviceItem.maintAmount = maintItem.amount;
                                serviceItem.periodicAmount = maintItem.periodicAmount;
                                maintAmount += maintItem.amount;
                                if (serviceRows) {
                                    this.totalAccServ =  result.accumulatedService ;
                                    this.changeOffrData.accumulatedService = result.accumulatedService;
                                }
                                
                            }
                        });
                    });

                    // recalculate params for Calculation Params table after calculation API
                    if (this.isInternalDLLMember) {
                        this.recalculateCalculationParamsAfterCalcAPI(result);
                    }
                    
                   
                }
                this.calculationCalloutCounter = this.calculationCalloutCounter - 1;
                if( this.calculationCalloutCounter == 0 && this.isAllValueCorrect){
                    this.enableSelectCustomerButton = true; 
                }
                this.showSpinnerOnFooter = false;               
            })
            .catch(error => {
                showPopUpNotification(
                    this,          
                    reduceErrors(error), 
                    'error'
                );    
                this.showSpinnerOnFooter = false; 
                this.enableSelectCustomerButton = false;             
            });
             
        } else{
            this.enableSelectCustomerButton = false; 
        }

    }
   
    // go to the next stage
    handleNextStep() {
        
        switch (this.currentScreen) {
            case this.quoteStatuses.Calculation:
                if (this.curntQuoteStage === undefined || this.curntQuoteStage === '' || this.curntQuoteStage === this.quoteStatuses.Calculation) {
                    if (this.isAllValuePresent && this.isAllValueCorrect) {
                        
                        this.handleSaveQuote();
                    } else if (!this.isAllValuePresent) {
                        showPopUpNotification(this,this.labels.product_row_error,'error');
                    } else if (!this.isAllValueCorrect) {
                        showPopUpNotification(this,this.labels.Error_Please_Enter_Valid_Values,'error');
                    }       
                } else {
                    //console.log('nextscreen4');
                    this.showCustomerScreen();
                    //console.log('nextscreen5');
                }
                break;
            case this.quoteStatuses.Customer:
                if (this.curntQuoteStage === this.quoteStatuses.Calculation) {              
                    this.selectCustomer();
                } else {
                    if (this.curntQuoteStage === this.quoteStatuses.Declined || this.curntQuoteStage === this.quoteStatuses.Assessment || this.curntQuoteStage === this.quoteStatuses.Refer || this.curntQuoteStage === this.quoteStatuses.BlockedDueToMultiplePG) {
                        showPopUpNotification(this,this.labels.nxt_step_quote_error + this.curntQuoteStage + '" status','error');
                    } else if (this.curntQuoteStage === this.quoteStatuses.Approved || this.curntQuoteStage === this.quoteStatuses.ApprovedWithConditions || this.curntQuoteStage === this.quoteStatuses.DocumentsGenerated || this.curntQuoteStage === this.quoteStatuses.PendingESign) {
                        this.showDocumentsScreen();
                    }
                }
                break;
            case this.quoteStatuses.Documents:
                if (this.curntQuoteStage === this.quoteStatuses.Approved || this.curntQuoteStage === this.quoteStatuses.ApprovedWithConditions) {
                    this.generateContract();
                }else if(this.curntQuoteStage === this.quoteStatuses.DocumentsGenerated || this.curntQuoteStage === this.quoteStatuses.PendingESign){
                    this.showESignScreen();
                }else if(this.isDocumentQstnExist){
                    this.showReviewScreen();
                }
                //this.hideCancelOpptyOption = true; //if document generated then hide cancel oppty option 
                break;
            case this.quoteStatuses.Review:
                this.redirectToHomePage();
                break;
            default:
                console.error('No such stage exists');
        }       
    }
    
    /**
     * 
     * @returns submitApplication response
     */
    createSubmitApplicationRequest(){
       
        const submitAppReq = {
            oppOwner : this.dealDetails.oppOwner,
            programBU : this.dealDetails.programBU,
            oppCreationDate : this.dealDetails.oppCreationDate,
            financialProductName : this.dealDetails.financialProductName,
            offerName : this.dealDetails.offerName,
            oppCurrency : this.dealDetails.oppCurrency,
            qouteTerm : this.dealDetails.qouteTerm,
            paymentFrequency : this.dealDetails.paymentFrequency,
            advanceArrear : this.dealDetails.advanceArrear,
            oppFinancedAmount : this.dealDetails.oppFinancedAmount,
            nominalInterestRate : this.dealDetails.nominalInterestRate,
            productInfoList : this.dealDetails.productInfoList,
            serviceInfoList : this.dealDetails.servicesInfoList
        }
        return submitAppReq;
    }

    /**Save quote on click of Select customer button in footer*/
    handleSaveQuote(){        
        //check if all prod and service rows has correct values or not:
       
        if (!this.checkValidValuesFotCalculation()) {
            return;
        }
    
        //filtering the list for deleting the quote lines which are deleted by user        
        let finalQuoteServiceLineLst = this.changeProdData.concat(this.changeServdata);        
        for(let eachId in finalQuoteServiceLineLst){          
            this.updateQuoteLineIdLst.push(finalQuoteServiceLineLst[eachId]['quotelineid']);
        }      
        const deleteLst = this.quotelineIdLst.filter(value => !this.updateQuoteLineIdLst.includes(value))
        //add the accumulated and insurance payment properties also
        this.changeOffrData.accumulatedService = this.totalAccServ;
        this.changeOffrData.insurancePayments = this.insurancePerFrqncy;
        this.changeOffrData.viewRentPerMonth = this.viewRentPerMonth;
        this.isLoading = true;

         //call apex method to save
         doSaveQuoteDetail({
            offeridstr: JSON.stringify(this.changeOffrData),
            productdetails : JSON.stringify(this.changeProdData),
            servicedetails : JSON.stringify(this.changeServdata),
            quoteid : this.quoteId,
            quoteAmountRateDetails : JSON.stringify(this.quoteAmountRateDetails),
            isNewVer : this.isNewVersion,
            deleteLineLst : deleteLst,
            opptyId : this.oppIdfromUrl,
            behaveOnUserId: this.behaveOnUserId,
        })
        .then(result => {  
            this.updateQuoteLineIdLst = [];//clear list after save quoteline item         
            this.primaryProduct = result.productInfoList[0];
            this.showSyncedQuote = false;

            //adding the newly created quote to the list of dropdown
            //only for creation of quote
            if(result && this.isNullOrZeroOrUndefined(this.quoteId)){
                this.submitAppRequest = { ...result };
                                 
                const newQuote = {
                    label : result.newQuoteDetailsStr.substring(0, result.newQuoteDetailsStr.indexOf('=')),
                    value : result.newQuoteDetailsStr.substring(0, result.newQuoteDetailsStr.indexOf('=')),
                    qid : result.newQuoteDetailsStr.substring( result.newQuoteDetailsStr.indexOf('=')+1,result.newQuoteDetailsStr.indexOf('❆')),
                    qnum : result.newQuoteDetailsStr.substring(result.newQuoteDetailsStr.indexOf('❆')+1,result.newQuoteDetailsStr.length)
                }                       
                this.restQtnameLst.unshift(newQuote); //adding the newly created quote name at the begining 
                //this.isLoading = false;  
               
                showPopUpNotification(this,this.labels.quote_create_success,'success');
                this.quoteId = result.newQuoteDetailsStr.substring( result.newQuoteDetailsStr.indexOf('=')+1,result.newQuoteDetailsStr.indexOf('❆'));
                this.latestQuoteName = result.newQuoteDetailsStr.substring(0, result.newQuoteDetailsStr.indexOf('=')); //to show the latest created cloned quote by default
                
            }else{
                showPopUpNotification(this,this.labels.quote_Updated_Success,'success');
            }    
            this.termFromUrl = result.qouteTerm;
            this.quoteChangeHandler(this.quoteId); //to show the updated values from databse
            
                this.showCustomerScreen();
               
        })
        .catch(error => {
            
            this.error = error;
            this.isLoading = false;
            showPopUpNotification(this,this.labels.contact_Admin_Error,'error');
            console.error(JSON.stringify(error));
        });
    }

    // check if all prod and service rows has correct values
    checkValidValuesFotCalculation() {
       
        //if itad column is there, and no value is selected in ITAD column, throw error
        const foundItadColumn = this.leasecols.find(element => element.label == 'ITAD');
        if(foundItadColumn.isHidden === false && this.changeOffrData?.hasOwnProperty('itadlevel') && this.changeOffrData['itadlevel'] == ''){
            this.isAllValuePresent = false;    
            showPopUpNotification(this,this.labels.ITAD_level_Error,'error');               
            return false;
        }

        for(const eachIndex in this.changeProdData){
            if(this.changeProdData[eachIndex]['Product'] == '' || this.changeProdData[eachIndex]['quantity'] == '' || this.changeProdData[eachIndex]['unitprice'] == ''){
                this.isAllValuePresent = false;    
                showPopUpNotification(this,this.labels.product_row_error,'error');               
                return false;
            } else if (this.changeProdData[eachIndex]['quantity'] > MAX_UNITS || this.changeProdData[eachIndex]['unitprice'] > MAX_UNIT_PRICE) {
                this.isAllValueCorrect = false;
                showPopUpNotification(this,this.labels.Error_Please_Enter_Valid_Values,'error');
                return false;
            }
        }

        for(const eachIndex in this.changeServdata){
            if (this.changeServdata[eachIndex]['Product'] === '' && this.changeServdata[eachIndex]['quantity'] === '' && this.changeServdata[eachIndex]['unitprice'] === '') {
            } else if (this.changeServdata[eachIndex]['Product'] == '' || this.changeServdata[eachIndex]['quantity'] == '' || this.changeServdata[eachIndex]['unitprice'] == '') {
                this.isAllValuePresent = false;    
                showPopUpNotification(this,this.labels.Error_Please_Enter_Valid_Values,'error');              
                return false;        
            } else if (this.changeServdata[eachIndex]['quantity'] > MAX_UNITS || this.changeServdata[eachIndex]['unitprice'] > MAX_UNIT_PRICE) {
                this.isAllValueCorrect = false;
                showPopUpNotification(this,this.labels.Error_Please_Enter_Valid_Values,'error');              
                return false;
            }
        }

        return true;
    }

    /**On click of New Version button */
    handleNewVersionBtn(event){ 
        this.isLoading = true;
        this.isNewVersion = true;  
        this.data = [];
        this.servicedata = [];
        this.offerData = [];
        this.leasegridColumnMeta=[];
        this.finalSmartDocCount=0;
        this.calculationCalloutCounter=0;
        const foundItadColumn = this.leasecols.find(element => element.label == 'ITAD');
        if(foundItadColumn.isHidden === false){
            //on new version, search if itad column is there in the offer section and remove it      
            foundItadColumn.isHidden = true;  
        }           
        getOfferDetailsOnNewVersion({behaveOnUserId: this.behaveOnUserId})
        .then(result => {           
            if(result){                
                this.refreshComp(result,false,false);
            }
            this.isLoading = false;
        })
        .catch(error => {
           
            this.error = error;
            this.isLoading = false; 
            showPopUpNotification(this,this.labels.contact_Admin_Error,'error');         
        });       
    }

   /**Clone Quote event */
   handleCopyQuoteProcess(event){   
    this.finalSmartDocCount=0;
    this.calculationCalloutCounter=0;    
        this.isLoading = true;
        doCopyQuoteDetails({
            copiedQuoteId : event.detail,
            behaveOnUserId: this.behaveOnUserId,
        }).then(newClonedQuote => {
            this.refreshComp(newClonedQuote,false,true);
            //adding the new cloned quote to the list of dropdown
            const clonedQtDetails = {
                label : newClonedQuote.clonedQuoteName,
                value : newClonedQuote.clonedQuoteName,
                qid : newClonedQuote.quoteid,
                qnum : newClonedQuote.clonedQuoteNumber
            }                   
            this.restQtnameLst.unshift(clonedQtDetails); //adding the newly created quote name at the begining  

            if (newClonedQuote.infoMessage != null) {
                showPopUpNotification(this,newClonedQuote.infoMessage,'info');
            } else {
                showPopUpNotification(this,this.labels.quote_Clonned_success,'success');
            }
            
            this.latestQuoteName = newClonedQuote.latestQuote; //to show the latest created cloned quote by default
            this.totalPricewithoutCrncy = newClonedQuote.totalFinanceVal;
            this.opptyName = newClonedQuote.opptyName;
            this.quoteId = newClonedQuote.quoteid;  
            this.isLoading = false;
            this.showSyncedQuote = false;
        }).catch(error => {
          
            this.error = error;  
            this.isLoading = false;
            showPopUpNotification(this,this.labels.contact_Admin_Error,'error');
        });       
    }

    //do this because when we change any paremeter in list or object, then it donot reflect, so we need to send primitve data types, hence stingify 
    get restQuotetNameLastStr(){
        return JSON.stringify(this.restQtnameLst);
    }

    /**Table refresh on Quote change */
    handleQuoteChange(event){
        this.isLoading = true;
        this.quoteChangeHandler(event.detail);      
    }

    /**handler method for quote change*/
    // added new parameter as part of 721477
    quoteChangeHandler(quoteIdStr){
        getQuoteDetailsOnChange({
            quoteId : quoteIdStr
        }).then(resultQtChng => {   
            this.selCusScreen = false;  //need to show on quote status, modify later
            this.selCalculationScreen = true; //need to show on quote status, modify later         
            this.curntQuoteStage = resultQtChng.quoteStatus;          
            this.refreshComp(resultQtChng,false,true);          
            this.totalPricewithoutCrncy = resultQtChng.totalFinanceVal; 
            this.opptyName = resultQtChng.opptyName;
            this.quoteId = resultQtChng.quoteid;  
            this.isLoading = false; 
            this.showSyncedQuote = false;
        })
        .catch(error => {
            this.error = error; 
            showPopUpNotification(this,this.labels.contact_Admin_Error,'error');
        });
    }

    /**Screen select logic */
    selectScreen() {
        switch (this.curntQuoteStage) {
            case this.quoteStatuses.Calculation:
                this.showCustomerScreen();
                break;
            case this.quoteStatuses.Approved:
            case this.quoteStatuses.ApprovedWithConditions:
                this.showDocumentsScreen();
                break;
            case this.quoteStatuses.Assessment:
            case this.quoteStatuses.Refer:
            case this.quoteStatuses.Declined:    
            case this.quoteStatuses.BlockedDueToMultiplePG:       
                this.showCustomerScreen();
               break;  
            case this.quoteStatuses.DocumentsGenerated:
            case this.quoteStatuses.PendingESign: 
            case this.quoteStatuses.PendingDocumentation: 
            case this.quoteStatuses.PendingValidation: 
            case this.quoteStatuses.PendingInformation:
            case this.quoteStatuses.PendingReview:
            case this.quoteStatuses.ReviewCompleted:
                if(!this.isDocumentQstnExist){
                    this.showESignScreen();
                }else{
                    this.showReviewScreen();
                }     
                break;  
            //case this.quoteStatuses.ReviewCompleted:
               //this.showReviewScreen();
               // break;  
            default:
                this.showCalculationScreen();
        }
    }

    handleAssesmentButton(event){
        this.enableAssessmentButton = event.detail;
    }

    // then user select customer
    selectCustomer() {
        this.getCustomer();
        if (this.customerData === undefined) {
            showPopUpNotification(
                this,     
                this.labels.customer_not_selected, 
                'error'
            );
        } else {
            this.showCreditCheckModal();
            if (this.customerData.companySFDCId != undefined) {
                this.makeSubmitAppCall();
            } else {              
                if(!this.customerData.companyId.includes('-')){
                    this.customerData.companyId = this.customerData.companyId.replace(/(\d{6})(\d{4})/, "$1-$2")
                }           
                updateDealAndSaveCustomer({ 
                    customerInfo: JSON.stringify(this.customerData.companyData), 
                    customerExtId: this.customerData.companyId, 
                    quoteId: this.quoteId 
                })
                .then(result => {
                    this.template.querySelector('c-customer-search-cmp').showSelectedCustomer();
                    this.customerData.companySFDCId = result;                   
                    this.makeSubmitAppCall();
                })
                .catch(error => {
                    showPopUpNotification(
                        this,
                        reduceErrors(error), 
                        'error'
                    );
                    this.hideCreditCheckModal();
                });
            }
        }
    }

    /**Send paramtrs for submit application callout in JSON */
    getSubmitAppParams() {
       
        return JSON.stringify({
            oppId: this.oppIdfromUrl,
            oppName: this.opptyName,
            quoteId: this.quoteId,
            oppOwner : this.submitAppRequest.oppOwner,
            programBU : this.submitAppRequest.programBU,
            oppCreationDate : this.submitAppRequest.oppCreationDate,
            financialProductName : this.submitAppRequest.financialProductName,
            offerName : this.submitAppRequest.offerName,
            oppCurrency : this.submitAppRequest.oppCurrency,
            qouteTerm : this.submitAppRequest.qouteTerm,
            paymentFrequency : this.submitAppRequest.paymentFrequency,
            advanceArrear : this.submitAppRequest.advanceArrear,
            oppFinancedAmount : this.submitAppRequest.oppFinancedAmount,
            nominalInterestRate : this.submitAppRequest.nominalInterestRate,
            productInfoList : this.submitAppRequest.productInfoList,
            serviceInfoList: this.submitAppRequest.serviceInfoList,
            customerExtId: this.customerData.companyId,
            customerId: this.customerData.companySFDCId,
            customerStreet: this.customerData.companyStreet,
            customerCity: this.customerData.companyCity,
            customerPostalCode: this.customerData.companyZipCode,
            customerLegalName: this.customerData.companyLegalName,
            partnerName : this.partnerName,
            partnerEmail : this.partnerEmail,
        });
    }

     /**
     * Refresh the customer screen on update of status field from DCV
     */
    refreshCustomerScreen() {
        switch (this.curntQuoteStage) {
            case this.quoteStatuses.Assessment: 
                break;
            case this.quoteStatuses.ApprovedWithConditions: 
                this.template.querySelector('c-customer-search-cmp').showSelectedCustomer();
                break;
            case this.quoteStatuses.Refer: 
                this.template.querySelector('c-customer-search-cmp').showNotification(this.labels.manual_Assessment_msg, 'info');
                break;
            case this.quoteStatuses.Declined:
                this.template.querySelector('c-customer-search-cmp').showNotification(this.labels.credit_has_been_rejected, 'error');
                break;
            case this.quoteStatuses.Approved:
                this.showDocumentsScreen(); 
                showPopUpNotification(
                    this,       
                    this.labels.credit_has_been_approved, 
                    'success'
                );
                break;
            case this.quoteStatuses.BlockedDueToMultiplePG: 
                this.template.querySelector('c-customer-search-cmp').showNotification(this.labels.Error_Quote_Is_Blocked, 'error');
                break;    
            default:
                this.hideCreditCheckModal();
                console.error('No such status exists');
        }
    }

    /**
     * Show credit check modal popup
     */
    showCreditCheckModal() {
        this.showCreditCheck = true;
    }

    /**
     * hide the credit check modal popup
     */
    hideCreditCheckModal() {
        this.showCreditCheck = false;
    }

    /**
     * make the Apex submit application callout
     */
    makeSubmitAppCall() {
        //console.log('submit app params: ' + this.getSubmitAppParams());
        sendSubmitAppRequest({ 
            parameters: this.getSubmitAppParams(),
            saveLogsAsync: true 
        })
        .then(result => {
            
            const resultParse = JSON.parse(result); 
            if (result === '200') {
                this.makeCreditAssessmentCall();
            } else {
                this.hideCreditCheckModal();
                showPopUpNotification(this,resultParse.message,'error');
            }
        })
        .catch(error => {
            this.hideCreditCheckModal();
            showPopUpNotification(
                this,
                reduceErrors(error), 
                'error'
            );
        });
    }

     /**
     * Update the Quote status field
     */
    updateQuoteStatus(inputParam){
        updateQuoteStatus({ quoteId: this.quoteId,status : inputParam })
        .then(result => {
            this.curntQuoteStage = inputParam;
        })
        .catch(error => {
            showPopUpNotification(
                this,
                reduceErrors(error), 
                'error'
            );
        });
    }

    /**
     * make the Apex credit assessment callout
     */
    makeCreditAssessmentCall() {
        this.updateQuoteStatus('Assessment');
        sendCreditAssessmentRequest({ 
            quoteId: this.quoteId,
            saveLogsAsync: true
        })
        .then(result => {         
            if (result != '200') {
                this.curntQuoteStage = this.labels.Calculation;
                this.hideCreditCheckModal();
                showPopUpNotification(this,this.labels.credit_Assesment_error,'error');
            }
        })
        .catch(error => {
            this.hideCreditCheckModal();
            showPopUpNotification(this,this.labels.credit_Assesment_error,'error');
        });
    }

    /**
     * Show the customer screen on click of the progressive bar
     */
    showCustomerScreen() {
        if (this.currentScreen === this.quoteStatuses.Customer) {
            this.template.querySelector('c-customer-search-cmp').showSelectedCustomer();
        } else {
            this.currentScreen = this.quoteStatuses.Customer;
        }
        this.selCalculationScreen = false;  
        this.selCusScreen = true;
        this.selDocsScreen = false;
        this.selEsignScreen = false;
        this.selReviewScreen = false;
        //this.enableAssessmentButton = false;
        if (this.curntQuoteStage === this.quoteStatuses.Assessment) {
            this.showCreditCheckModal();
        }
    }
    
    /**
     * Show the document screen on click of the progressive bar
     */
    showDocumentsScreen() {
        
        this.currentScreen = this.quoteStatuses.Documents;
        this.selCalculationScreen = false;  
        this.selCusScreen = false;
        this.selDocsScreen = true;
        this.selEsignScreen = false;
        this.selReviewScreen = false;
    }

     /**
     * Show the calculation screen on click of the progressive bar
     */
    showCalculationScreen() {
        this.currentScreen = this.quoteStatuses.Calculation;
        this.selCalculationScreen = true;  
        this.selCusScreen = false;
        this.selDocsScreen = false;
        this.selEsignScreen = false;
        this.selReviewScreen = false;
        this.hideServiceSection = (this.curntQuoteStage != this.quoteStatuses.Calculation && this.curntQuoteStage && this.servicedata.length === 0);
        if (this.isInternalDLLMember) {
            this.setCalculationParams(this.calculationParamsFromExistingQuote, false);
        }
        this.showHideAddButton();
    };

    /**Show the e-sign screen */
    showESignScreen(){
        this.currentScreen = this.screenNamesEN.ESign;
        this.selCalculationScreen = false;  
        this.selCusScreen = false;
        this.selDocsScreen = false;
        this.selEsignScreen = true;
        this.selReviewScreen = false;
    }
    /**Redirect to home page on click of home button in the review screen */
    redirectToHomePage(){
        window.location.href = this.labels.Partner_Portal_URL;
   }

    /**Show the Checklist/Review screen */
    showReviewScreen(){
        this.currentScreen = this.quoteStatuses.Review;
        this.selCalculationScreen = false;  
        this.selCusScreen = false;
        this.selDocsScreen = false;
        this.selEsignScreen = false;
        this.selReviewScreen = true;
    }
    /**Generate the contract */
    generateContract(){ 
        if(this.template.querySelector('c-contract-generation-screen').isLoading){
            showPopUpNotification(
                this,       
                this.labels.Documents_generation_in_progress, 
                'info'
            );
            return;
        }
        let contactData = this.template.querySelector('c-contract-generation-screen').getContactAndDeliveryDetails();
       
        if(contactData && this.isNullOrZeroOrUndefined(contactData.contactName) || this.isNullOrZeroOrUndefined(contactData.contactEmail)){
            showPopUpNotification(
                this,       
                this.labels.enter_data_error, 
                'error'
            );
        }else{         
            this.template.querySelector('c-contract-generation-screen').isLoading = true;
            this.getDocumentsFromSmartcom(contactData); //call method to save quote
            
        }
    }

    /**
     * method to create the submit app request from document generation screen
     * @returns submitapplication response
     */
    getParamsForSubmitAppFromDocumentsScreen() {
        let contactData = this.template.querySelector('c-contract-generation-screen').getContactAndDeliveryDetails();
        let customerInfo = this.template.querySelector('c-contract-generation-screen').customerInfo;

        let lesseeContact = {
            name: contactData.contactName,
            email: contactData.contactEmail,
            phoneNumber: contactData.contactPhone,
        };

        let deliveryAddress = {
            street: contactData.contactStreet,
            city: contactData.contactCity,
            postalCode: contactData.contactZipCode,
        }

        let submitAppParams = {
            oppId: this.oppIdfromUrl,
            oppName: this.opptyName,
            quoteId: this.quoteId,
            oppOwner : this.submitAppRequest.oppOwner,
            programBU : this.submitAppRequest.programBU,
            oppCreationDate : this.submitAppRequest.oppCreationDate,
            financialProductName : this.submitAppRequest.financialProductName,
            offerName : this.submitAppRequest.offerName,
            oppCurrency : this.submitAppRequest.oppCurrency,
            qouteTerm : this.submitAppRequest.qouteTerm,
            paymentFrequency : this.submitAppRequest.paymentFrequency,
            advanceArrear : this.submitAppRequest.advanceArrear,
            oppFinancedAmount : this.submitAppRequest.oppFinancedAmount,
            nominalInterestRate : this.submitAppRequest.nominalInterestRate,
            productInfoList : this.submitAppRequest.productInfoList,
            serviceInfoList: this.submitAppRequest.serviceInfoList,
            customerExtId: customerInfo.companyId,
            customerId: customerInfo.companySFDCId,
            customerStreet: customerInfo.companyAddress.split(',')[0],
            customerCity: customerInfo.companyAddress.split(',')[1],
            customerPostalCode: customerInfo.companyZipCode,
            customerLegalName: customerInfo.companyName,
            partnerName: this.partnerName,
            partnerEmail: this.partnerEmail,
            lesseeContact: lesseeContact,
            deliveryAddress: deliveryAddress,
            insuranceMode: this.template.querySelector('c-contract-generation-screen').insuranceRadioValue,
            reference : contactData.contactReference
        }
          return submitAppParams;
    }

    /**
     * Generate smartcomm documents
     */
    getDocumentsFromSmartcom(contactData) {
        let specialTnCId = this.getSpecialTermsCondtionIds();
        contactData.specialTnCId = specialTnCId; 
        

        createCont_Quote({
            contactAddressDetails : JSON.stringify(contactData)
        })
        .then(result => {          
            if(!result.includes('Error')){
                //if no error, do submit app callout
                let submitAppParams = this.getParamsForSubmitAppFromDocumentsScreen();
                submitAppParams.specialTnCId = specialTnCId; 
               
                sendSubmitAppRequest({ 
                    parameters: JSON.stringify(submitAppParams),
                    saveLogsAsync: true 
                }).then(submitAppResult => {
                    const resultParse = JSON.parse(submitAppResult); 
                    if (submitAppResult === '200') {
                        
                        //generate smartcomm documents
                        //this.getDocumentsFromSmartcom(contactData);

                        genSmartCommDoc({
                            contactAddressDetails : JSON.stringify(contactData),
                            behaveOnUserId: this.behaveOnUserId
                        }).then(genDocResult => {
                            console.log('Doc generated');
                        }).catch(error => {
                            this.template.querySelector('c-contract-generation-screen').isLoading = false;
                            showPopUpNotification(
                                this,
                                reduceErrors(error), 
                                'error'
                            );
                        });


                    } else {
                        this.template.querySelector('c-contract-generation-screen').isLoading = false;
                        showPopUpNotification(this,resultParse.message,'error');
                    }
                })
                .catch(error => {
                    this.template.querySelector('c-contract-generation-screen').isLoading = false;
                    showPopUpNotification(
                        this,
                        reduceErrors(error), 
                        'error'
                    );
                });
                this.disableContGenFields = true; //when status is document generated               
            }else{              
                this.template.querySelector('c-contract-generation-screen').isLoading = false;
                let errorMsg = '';
                if(result.includes('INVALID_EMAIL_ADDRESS')){
                    errorMsg = this.labels.Invalid_Email;
                }
                showPopUpNotification(
                    this,
                    errorMsg, 
                    'error'
                );
            }
        })
        .catch(error => {    
            this.error = error;
            this.isLoading = false;
            showPopUpNotification(
                this,
                reduceErrors(error), 
                'error'
            );
        });
    }

    /**
     * Get Id for selected special terms and conditiond from document screen
     */
    getSpecialTermsCondtionIds() {
        let specialTermsCondtion = this.template.querySelector('c-contract-generation-screen').getSpecialTermsCondtion();
        let termsCondtionArr = [];

        specialTermsCondtion.forEach(item => {
            if (item.isChecked) {
                termsCondtionArr.push(item.recordId);
            }
        });

        return termsCondtionArr;
    }

    /**
     * Show/hide add button on the product/service
     */
    showHideAddButton(){
        //let showButtons = !(this.curntQuoteStage === this.quoteStatuses.Approved || this.curntQuoteStage === this.quoteStatuses.Declined || this.curntQuoteStage === this.quoteStatuses.ApprovedWithConditions || this.curntQuoteStage === this.quoteStatuses.DocumentsGenerated || this.curntQuoteStage === this.quoteStatuses.PendingESign || this.curntQuoteStage === this.quoteStatuses.PendingDocumentation || this.curntQuoteStage === this.quoteStatuses.PendingValidation || this.curntQuoteStage === this.quoteStatuses.PendingInformation  || this.curntQuoteStage === this.quoteStatuses.PendingReview || this.curntQuoteStage === this.quoteStatuses.ReviewCompleted || this.disabledDueToUnavailibleProduct);
        let showButtons = !(this.disableFieldStages.includes(this.curntQuoteStage) || this.disabledDueToUnavailibleProduct || this.disabledCalculationParams);
        this.productShowAddDelButton = showButtons;
        this.serviceShowAddDelButton = false;//showButtons;//Tempory fix for multiple Maintenace;
    }

    getCustomer() {
        this.customerData = this.template.querySelector('c-customer-search-cmp').getCustomer();
    }

    // handle notification from child component
    handleNotification(event) {
        showPopUpNotification(
            this,
            event.detail.message, 
            event.detail.variant
        );
    }

    /**When user clicks on previous step on progress steps ,show the section accordingly */
    handleProgressStep(event){
      
        if(event.detail == this.quoteStatuses.Calculation){
            this.showCalculationScreen();
        }else if(event.detail == this.quoteStatuses.Customer){
            this.showCustomerScreen();
        }else if(event.detail == this.quoteStatuses.Documents){
            this.showDocumentsScreen();
        }else if(event.detail == this.screenNamesEN.ESign){
            this.showESignScreen();
        }else if(event.detail == this.quoteStatuses.Review){
            this.showReviewScreen();
        }    
    }

    /**
     * Message subscription platform event. on change of status by DCV
     */
    messageReceived(event) {
        const message = event.detail;
        if (message.data.payload.Quote_Id__c != this.quoteId) {
            return;
        }
        //incase of credit asssement response, hide the modal window
        if (this.curntQuoteStage === this.quoteStatuses.Assessment) {
            this.curntQuoteStage = message.data.payload.Quote_Status__c;
            this.refreshCustomerScreen();
            this.hideCreditCheckModal();
        }
        
         //in case of smartcomm response, move to e-sign page only when status is document gen, else keep in the contract page
         if (message.data.payload.Quote_Status__c === this.quoteStatuses.DocumentsGenerated) {  
            
            const eventMessage = message.data.payload.Message__c.split('#');

            this.finalSmartDocCount = this.finalSmartDocCount+1; 
           
            //Update quote if all Docs genrated successfully and moved to next screen else unblock window and show error message
            if(this.finalSmartDocCount === parseInt(eventMessage[0])){
                this.curntQuoteStage = message.data.payload.Quote_Status__c;      
                this.showESignScreen();

                //update quote after all Docs genrated successfully
                this.updateQuoteStatus(this.quoteStatuses.DocumentsGenerated);
                this.template.querySelector('c-contract-generation-screen').isLoading = false;
                
                showPopUpNotification(
                    this,                    
                    eventMessage[1],
                    'success'
                );

            }    
        }else if(message.data.payload.Quote_Status__c === 'Failed'){
            this.template.querySelector('c-contract-generation-screen').isLoading = false;
            
            showPopUpNotification(
                this,
                message.data.payload.Message__c, 
                'error'
            );
        }
        
    }

    handleGetData() {
        let datafromchild = this.template.querySelector('c-table-ui-control').rows;
    }

    getFinalRentalValue(paymentFrequency,rentalVal){
        //console.log('Inside getFinalRentalValue...'+Math.round(this.getRentalAmount(paymentFrequency,rentalVal)));        
        return this.viewRentPerMonth == true && rentalVal
            ? Math.round(this.getRentalAmount(paymentFrequency,rentalVal))
            : rentalVal 
                ? Math.round(rentalVal)
                : 0;
    }
    
    getRentalAmount(paymentFrequency, finalRentalVal){
        return  paymentFrequency == (this.frequency['Quarterly']).toLowerCase() || paymentFrequency == this.frequency['Quarterly'] ? (finalRentalVal * 4)/12 :
								paymentFrequency == (this.frequency['Semi_Annually']).toLowerCase()|| paymentFrequency == this.frequency['Semi_Annually'] ? (finalRentalVal * 2)/12 :
								paymentFrequency == (this.frequency['Annually']).toLowerCase()|| paymentFrequency == this.frequency['Annually'] ? (finalRentalVal)/12 : finalRentalVal; 
        						
	}
    
     /* CALCULATION PARAMS TABLE START*/

    // hide and show Calculation Table
    handleCalculationParams(event) {
        this.showCalculationDetails = !this.showCalculationDetails;
        let elem = this.template.querySelector('.calculation-tables');
        elem.classList.toggle("slds-size_1-of-1");  
        elem.classList.toggle("slds-size_3-of-5");  
        let btn = this.template.querySelector('lightning-button.calculationParams');
        btn.iconName = (this.showCalculationDetails) ? "utility:close" : "utility:display_text"
    }

    // set values for Calculation Params by default
    setDefaultCalculationParams() {
        let calculationTableParams = {};

        // get rate value
        if (!this.rateName) {
            this.getRateInfo(
                this.offerData[0].Offer__c, 
                this.offerData[0].term, 
                this.offerData[0].frequency, 
                this.offerData[0].interest, 
            );
        }

        // get data for Finance Amount Table
        calculationTableParams.financedAmount = {
            'Sum Hardware (SEK)': 0,
            'Sum Soft Cost (SEK)': 0,
            'Sum Installation (SEK)': 0,
            //'Refinanced Amount': '',
            'Sum Financed Amount': 0,
        };

        // get data for Rate Table
        calculationTableParams.rate = {
            'Reference Rate': this.rateName,
            'Rate': this.baseRate,
            'Cost of Funds': this.costOfFunds,
            'Margin Partner': '',
            'Sum Nominal Rate [%]': '',
        };

        // get data for Lease Table
        calculationTableParams.leaseCalculation = {
            'n = Term / Payment Frequency': '',
            'Annual Rate': '',
            'PV = Financed Amount - Downpayment': '',
            'FV = Residual Value % * Sum Hardware':  '',
            's = In Advance = 1 / In arrears = 0': this.defaultPaymentTiming == 'in-advance' ? 1 : 0,
            'PMT': '',
        };

        // get data for Residual Value Table
        calculationTableParams.residualValue = {
            'residualValues': [],
        };

        // get data for Purchase Optin Table
        calculationTableParams.purchaseOption = {
            'purchaseOptions': [],
        };

        // get data for Insurance Table
        calculationTableParams.insurance = {
            'insurance': [],
        };

        this.calculationParams = calculationTableParams;
    }

    // set values for Calculation Params for existing quote or after Calculation API call
    setCalculationParams(calculationParams) {
        // reset all values by default
        this.setDefaultCalculationParams();

        let productIDs = [];

        this.changeProdData.forEach(item => {
            if (item.productType === 'Asset Soft' || item.productType === 'Asset Hard') {
                this.calculationParams.financedAmount['Sum Hardware (SEK)'] += Number.parseInt(item.totalprice.replace(',' , ''));
            } else if (item.productType === 'Soft Cost') {
                this.calculationParams.financedAmount['Sum Soft Cost (SEK)'] += Number.parseInt(item.totalprice.replace(',' , ''));
            } else if (item.productType === 'Installation') {
                this.calculationParams.financedAmount['Sum Installation (SEK)'] += Number.parseInt(item.totalprice.replace(',' , ''));
            }

            productIDs.push(item.Product);
        });

        this.calculationParams.financedAmount['Sum Financed Amount'] = calculationParams.sumFinancedAmount;
        
        // get data for Rate Table
        this.calculationParams.rate['Sum Nominal Rate [%]'] = calculationParams.sumNominalRate;
        // get and set Margin Matrix value for Rate table
        this.getMarginMatrixValue(calculationParams.sumFinancedAmount);

        // get data for Lease Table
        this.calculationParams.leaseCalculation = {
            'n = Term / Payment Frequency': calculationParams.numberOfPayments,
            //'Annual Rate = Nominal Rate * Payment Frequency': Math.round((calculationParams.annualRate + Number.EPSILON) * 100) / 100,
            'Annual Rate': calculationParams.sumNominalRate,
            'PV = Financed Amount - Downpayment': calculationParams.pv,
            'FV = Residual Value % * Sum Hardware':  calculationParams.futureValue,
            's = In Advance = 1 / In arrears = 0': this.defaultPaymentTiming.toLowerCase() === 'in-advance' ? 1 : 0,
            'PMT': Math.round(calculationParams.pmt),
        };

        // get data for Residual Value and Insurance Tables
        this.getRVandInsurance(this.offerData[0].Offer__c, productIDs, this.offerData[0].term);    

    }

    // get Margin Matrix value for Rate table
    getMarginMatrixValue(financeAmount) {
         //getMarginMatrixValue({behaveOnUserId: this.behaveOnUserId, selectedTermValue: this.offerData[0].term, selectedAmount: financeAmount})
         getMarginMatrixValue({behaveOnUserId: this.behaveOnUserId, selectedTermValue: this.changeOffrData.term, selectedAmount: financeAmount})        
         .then(result => {
            this.calculationParams.rate['Margin Partner'] = result.toFixed(2);
        })
        .catch(error => {
            showPopUpNotification(this, reduceErrors(error), 'error');
        })
    }

    // convert frequency to number of months
    getPaymentFrequencyInt(frequency) {
        let paymentFrequency; 
        frequency = frequency.toLowerCase();

        if (frequency === 'monthly') {
            paymentFrequency = 1;
        } else if (frequency === 'quarterly') {
            paymentFrequency = 3;
        } else if (frequency === 'semi-annually') {
            paymentFrequency = 6;
        } else if (frequency === 'annually') {
            paymentFrequency = 12;
        }

        return paymentFrequency;
    }

    // get RV and Insurance value per product
    getRVandInsurance(offerId, productIDs, term) {
        // remove empty string values 
        productIDs.forEach((item, index) => {
            if (item === '') {
                productIDs.splice(index, 1);
            }
        });

        // check id user selected any product
        if (productIDs.length === 0) {
            return;
        }

        getRVandInsuranceValues({
            offerId: offerId, 
            productIDs: productIDs,
            term: term
        })
        .then(result => {
            if (!result) {
                return;
            }

            this.calculationParams.residualValue.residualValues = [];
            this.calculationParams.purchaseOption.purchaseOptions = [];
            this.calculationParams.insurance.insurance = [];

            JSON.parse(result).forEach(item => {
                this.changeProdData.forEach(prodItem => {
                    if (prodItem.Product === item.productId) {
                        if (prodItem.residualValue != null && prodItem.residualValue != 0) {
                            let appliedRV = Math.round(((prodItem.residualValue / prodItem.unitprice * 100) + Number.EPSILON) * 100) / 100;

                            let rv = (item.residualValue?.minRV && item.residualValue?.maxRV)
                                ? `${appliedRV}% (${item.residualValue.minRV}% - ${item.residualValue.maxRV}%)`
                                : `${appliedRV}%`;

                            if (this.isPurchaseOptionApplicableForQuote) {
                                this.calculationParams.purchaseOption.purchaseOptions.push({
                                    'productName': item.productName, 
                                    'purchaseOption': rv,
                                });
                            } else {
                                this.calculationParams.residualValue.residualValues.push({
                                    'productName': item.productName, 
                                    'rvMatrix': item.residualValue?.rvMatrixName,
                                    'category': item.residualValue?.category,
                                    'rvValue': rv,
                                });
                            }    
                        }
        
                        if (prodItem.insuranceAmount != null && prodItem.insuranceAmount != 0) {
                            let appliedInsurance = Math.round(((prodItem.insuranceAmount / prodItem.unitprice * 100) + Number.EPSILON) * 100) / 100;
                            let insurance = (item.insurance?.minMargin && item.insurance?.maxMargin)
                                ? `${appliedInsurance}% (${item.insurance.minMargin}% - ${item.insurance.maxMargin}%)`
                                : `${appliedInsurance}%`;

                            this.calculationParams.insurance.insurance.push({
                                'productName': item.productName, 
                                'insuranceCode': item.insurance?.code,
                                'insuranceValue': insurance,
                            });
                        } 
                    }
                })
                
            });
        })
        .catch(error => {
            console.error('error: ' + reduceErrors(error));
            showPopUpNotification(this, reduceErrors(error), 'error');
        })
    }

    // calculate Calculation Params for qoute based on database
    calculateCalculationParamsFromExistingQuote(result) {
        let quotePaymentFrequency = result.submitAddWrapper?.paymentFrequency;
        let frequency = quotePaymentFrequency ? this.getPaymentFrequencyInt(quotePaymentFrequency) : null;

        let calculationParamsFromExistingQuote = {};
        calculationParamsFromExistingQuote.sumFinancedAmount = result.totalFinanceVal;
        calculationParamsFromExistingQuote.sumNominalRate = result.nominalInterestRate;
        calculationParamsFromExistingQuote.numberOfPayments = (result.submitAddWrapper?.qouteTerm && frequency) 
            ? result.submitAddWrapper?.qouteTerm / frequency 
            : '';
        calculationParamsFromExistingQuote.annualRate = (result.submitAddWrapper?.nominalInterestRate && frequency) 
            ? result.submitAddWrapper?.nominalInterestRate * frequency 
            : '';
        calculationParamsFromExistingQuote.futureValue = (result.futureValue) ? result.futureValue : '';
        calculationParamsFromExistingQuote.pv = (result.downpayment) ? result.totalFinanceVal - result.downpayment : '';
        calculationParamsFromExistingQuote.pmt = this.getFinalRentalValue(result['offrcls'][0]['defaultFreq'], result.rentalVal);

        this.calculationParamsFromExistingQuote = calculationParamsFromExistingQuote;
    }

    // recalculate Calculation Params for qoute based on Calculation API response
    recalculateCalculationParamsAfterCalcAPI(result) {
        let calculationParamsFromResponse = {};
        calculationParamsFromResponse.sumFinancedAmount = result.financeAmount;
        calculationParamsFromResponse.sumNominalRate = result.nominalInterestRate.toFixed(2);
        calculationParamsFromResponse.numberOfPayments = result.numberOfPayments;
        calculationParamsFromResponse.annualRate = result.nominalInterestRate * this.getPaymentFrequencyInt(result.paymentFrequency);
        calculationParamsFromResponse.futureValue = result.futureValue;
        calculationParamsFromResponse.pv = '';
        calculationParamsFromResponse.pmt = this.getFinalRentalValue(result.paymentFrequency,result.rentalAmount);

        this.setCalculationParams(calculationParamsFromResponse, true);
    }

    /* CALCULATION PARAMS TABLE END */

    /* PURCHASE OPTIONS START */

    handlePurchaseOptionColumn() {
        let purchaseOptionAmountColumn = this.leasecols.find(element => element.label == this.offerRVType.Purchase_Option);

        if (this.changeOffrData.isPurchaseOptionApplicable === true && purchaseOptionAmountColumn.isHidden === true) {
            // add column
            purchaseOptionAmountColumn.isHidden = false;
        } else if (this.changeOffrData.isPurchaseOptionApplicable !== true && purchaseOptionAmountColumn.isHidden === false) {
            // remove column
            purchaseOptionAmountColumn.isHidden = true;
        }

        this.getPurchaseOptions();
        this.handleRVColumnForProducts();
    }

    // get key-value pairs for Purchase Option combobox
    getPurchaseOptions() {
        let purchaseOptions = [
            { cellid : 'purchaseOption', label: this.labels.Yes, value: 'true' },
            { cellid : 'purchaseOption', label: this.labels.No, value: 'false'},
        ]

        this.leasegridColumnMeta = ( !this.leasegridColumnMeta ) 
            ? purchaseOptions 
            : this.leasegridColumnMeta.concat(purchaseOptions);
    }

    // show/hide Purchase Option Amount column for Product table
    handleRVColumnForProducts() {  
        let productWithAvailablePurchaseOption = this.changeProdData.find(
            element => element.isPurchaseOptionAvailable === true
        );
        let purchaseOptionAmountColumn = this.cols.find(element => element.label == 'Purchase Option');

        if (this.changeOffrData.purchaseOption === 'true' && productWithAvailablePurchaseOption !== undefined && purchaseOptionAmountColumn.isHidden === true) {      
            purchaseOptionAmountColumn.isHidden = false;
        } else if ((this.changeOffrData.purchaseOption !== 'true' || productWithAvailablePurchaseOption === undefined) && purchaseOptionAmountColumn.isHidden === false) {
            // reset purchase option value per product
            this.changeProdData.forEach(item => {
                item.residualValue = null;                
            });

            // remove column
            purchaseOptionAmountColumn.isHidden = true;

        }
    }

    // get isPurchaseOptionApplicableForQuote variable for footer to display/hide Total Purchase Option Amount
    get isPurchaseOptionApplicableForQuote() {
        return this.changeOffrData.purchaseOption === 'true' ? true : false;
    }

    /* PURCHASE OPTIONS END */

    /* ABILITY TO LOCK THE QUOTE START */

    // variable indicates if component (field, button) is disabled
    get isDisabled() {
        let condition = this.disabledDueToUnavailibleProduct || this.disabledCalculationParams;
        return (condition) ? true : false;
    }

    checkIfCalculalationParamsAreDisabled(result) {
        this.disabledCalculationParams = (this.isInternalDLLMember) ? false : result.disabledCalculationParams;
        this.enableSelectCustomerButton = !this.disabledCalculationParams;
    }

    /* ABILITY TO LOCK THE QUOTE END */

    // Show/hide insurance column in Product table for internal DLL members
    handleInsuranceColumn() {
        if (this.isInternalDLLMember !== true) {
            return;
        }

        //console.log('products: ' + JSON.stringify(this.changeProdData));

        let productWithAvailableInsurance = this.changeProdData.find(
            element => element.isInsuranceAvailable === true
        );
        let insuranceColumn = this.cols.find(element => element.label == 'Insurance');

        if (productWithAvailableInsurance !== undefined && insuranceColumn.isHidden === true) {
            // add column
            insuranceColumn.isHidden = false;
        } else if (productWithAvailableInsurance === undefined && insuranceColumn.isHidden === false) {
            // reset insurance value per product
            this.changeProdData.forEach(item => {
                item.insuranceAmount = null;
            });

            // remove column
            insuranceColumn.isHidden = true;

        }
    }
}