/*****************************************************************************************
Name: QuoteSetupController
===============================================================================================
Purpose: To handle the backend logic for quote calculation screen.
================================================================================================
================================================================================================
History
-------
VERSION        AUTHOR                  DATE              DETAIL
1.0                Anujit Das          14-01-2021        To save the quote on click of the Save customer button
* Version 1.1 @author Anujit @date 2021-02-15 quote update, QLI creation
* Version 1.2 @author Anujit @date 2021-07-15 US#505177
* Version 1.3 @author Ravisha Chugani @date 2021-12-21 US#667742
******************************************************************************************/

public with sharing class QuoteSetupController {
    
    final static Integer MAX_RESULTS = 50000; //no of result to display
    static string currentUserLocale = ''; //to hold the current user locale
    static String currentUserId = UserInfo.getuserId();
    static Map<string,double> itadProdNameToPriceMap = new Map<string,double>();  
    static Map<string,string> prodIdToItadProdNameMap = new Map<string,string>(); //productId to Itad product name   
    static string offer_programId = '';
    static Boolean viewRentPerMonth;
  
    //US505177
    @InvocableMethod(label='ReCalculation Process' description='Trigger when there is order fee or change of term in accept with condition' callout=true)
    public static void invokeRecalculation(List<Id> quoteIds) {
       
        ID jobID = System.enqueueJob(new RecalculationQueueable(quoteIds,'calculation'));
    }

    /*
    *Name: search
    *Purpose: to search on the Product and offer lookup field, depending on the user input values
     */
    @AuraEnabled(cacheable=true)
    public static List<LookupSearchResult> recordsSearch(String paramsForSearch) {
        
        SearchInputWrapper searchParams = (SearchInputWrapper) JSON.deserialize(paramsForSearch, SearchInputWrapper.class);
        String searchTerm = (searchParams.searchTerm != null) ? searchParams.searchTerm : '';
        String objectKey = searchParams.objectKey;
        list<String> selectedIds =  new list<String>();
        if(searchParams.selectedIds != null){
            for(string eachId : searchParams.selectedIds){
                selectedIds.add('\''+ String.escapeSingleQuotes(eachId)+'\'');
            }
        }
        String finalQuery = 'SELECT Id, Name ';    
        List<LookupSearchResult> results = new List<LookupSearchResult>();  
        
        if (objectKey == 'Product2') {
            String tableName = searchParams.tableName;
            finalQuery += ', Family' + ' FROM Product2 WHERE IsActive = TRUE AND Name LIKE  \'%' + String.escapeSingleQuotes(searchTerm.trim()) + '%\'';  
            if (tableName != null) {
                String additionalCondition = (tableName == 'Maintenance' || tableName == 'Service')
                    ? 'AND Family =\'Maintenance\''
                    : 'AND Family != \'Maintenance\' AND Family != \'ITAD\' ';
                finalQuery += additionalCondition; 
            }             
        } else if (objectKey == 'Offer__c'){
            finalQuery += 'FROM Offer__c WHERE isValid__c = true AND Name LIKE  \'%' + String.escapeSingleQuotes(searchTerm.trim()) + '%\'';
        } else {
            finalQuery += 'FROM ' + objectKey + ' WHERE Name LIKE  \'%' + String.escapeSingleQuotes(searchTerm.trim()) + '%\' ';
        }   
        if (!selectedIds.isEmpty()) {
            finalQuery += ' AND Id IN '+selectedIds;
        }
        finalQuery += ' LIMIT ' + MAX_RESULTS;
        System.debug('Final Query::::' + finalQuery);
        if (objectKey == 'Product2') {
            // map stores Product Id as a key and Asset Program Detail record as a value
            map<Id,Asset_Program_Detail__c> offrPrdMap = new map<Id,Asset_Program_Detail__c>();
            try {
                String offrId = searchParams?.offerId;
                offrPrdMap = new WoSSelector().getProductsFromProgram(offrId, searchTerm); 
                
                if (selectedIds.isEmpty()) {  
                    Set<Id> productIds = offrPrdMap.keySet();   
                    List<Product2> prodList = (List<Product2>) new WosSelector().getRecordsList(
                        // update query with Product Ids for current Asset Program
                        finalQuery.replace(' LIMIT ' + MAX_RESULTS, ' AND Id IN (\'' + String.join(new List<Id>(productIds), '\',\'') + '\') LIMIT ' + MAX_RESULTS)
                    );                           
                    for (Product2 op : prodList) {
                        if (offrPrdMap.size() > 0 && offrPrdMap.containsKey(op.id)) {
                            // check if Asset Program Detail is available
                            if (offrPrdMap.get(op.id).Is_Active__c) {
                                // send to UI data for available Asset Program Detail records
                                //results.add(new LookupSearchResult(op.id,objectKey,'',op.Name,'',op.Family,offrPrdMap.get(op.id).ITAD_Product__c !=null ? true : false, true));
                                results.add(new LookupSearchResult(op.id,objectKey,'',op.Name,'',op.Family,offrPrdMap.get(op.id).ITAD_Product__c !=null ? true : false,
                                                                   offrPrdMap.get(op.id).Default_Purchase_Option__c != null ? true : false, offrPrdMap.get(op.id).Insurance__c != null ? true : false, true));
                            }
                        } 
                    }                 
                } else {
                    List<Product2> prodList = (List<Product2>) new WosSelector().getRecordsList(finalQuery);
                    for (Product2 op : prodList) {
                        results.add(new LookupSearchResult(op.id,objectKey,'',op.Name,'',op.Family,offrPrdMap.get(op.id)?.ITAD_Product__c != null ? true : false,
                                                           offrPrdMap.get(op.id)?.Default_Purchase_Option__c != null ? true : false, offrPrdMap.get(op.id)?.Insurance__c != null ? true : false, offrPrdMap.get(op.id)?.Is_Active__c));             
                    }
                }
            }catch(Exception e) {
                ErrorLogger errorLog = new ErrorLogger();
                errorLog.logException(e, Constants.GENERIC_ERRORLOG_RECORDTYPE,'', true); 
                throw new ErrorLogger.ErrorLoggerException('Some exception occured while quering Product: ' + e.getMessage(),e);   
            }         
        }else if (objectKey == 'Offer__c'){
            try {
                Id behaveOnUserId = searchParams.behaveOnUserId;
                List<Offer__c> offerlst = (List<Offer__c>) new WosSelector().getRecordsList(finalQuery);
                List<Applicable_Offer__c> apOfrLst = new WoSSelector().getApplicableOffers(behaveOnUserId);
                Set<Id> offrIdSet = new Set<Id>();
                //partner user will get those offers where he is tagged to applicable offer's account's contact
                for (Applicable_Offer__c offr : apOfrLst) {
                    offrIdSet.add(offr.offer__c);
                }          
                for (Offer__c op : offerlst) {           
                    if (offrIdSet.contains(op.id)) {
                        results.add(new LookupSearchResult( op.id,objectKey,'',op.name,'',''));                 
                    }          
                }
            } catch(Exception e) {
                ErrorLogger errorLog = new ErrorLogger();
                errorLog.logException(e, Constants.GENERIC_ERRORLOG_RECORDTYPE,'', true); 
                throw new ErrorLogger.ErrorLoggerException('Some exception occured while quering Offer',e);     
            } 
        } else {
            try {
                 list<Sobject> sobjectList = new WosSelector().getRecordsList(finalQuery);
                 for (Sobject obj : sobjectList) {
                    results.add(new LookupSearchResult( obj.id,objectKey,'',(String)obj.get('Name'),'',''));
                 }
            } catch(Exception e) {
                ErrorLogger errorLog = new ErrorLogger();
                errorLog.logException(e, Constants.GENERIC_ERRORLOG_RECORDTYPE,'', true); 
                throw new ErrorLogger.ErrorLoggerException('Some error happened while quering '+objectKey, e);  
            } 
        }
        results.sort();

        return results; 
    }

    /**
    * Method Name: getNextHighestTerm
    * Purpose: To get the next highest term when user has selected term which is not standard term value. 
    */
    @TestVisible    
    public static String getNextHighestTerm(string selectableAgreementTerm, string term){
        
        List<String> termList = selectableAgreementTerm.split(';');
        
        for(String eachterm : termList){
            if(integer.valueof(eachterm) < integer.valueof(term)){
                continue;
            }
            else{
                return eachterm;
            }
        }
        return null;
    }
    
    /**
    *Method Name: getOfferDetailsOnNewVersion
    * Purpose: To get the offer details from the loggedin contact's account default applicable offer
    */
    @AuraEnabled(cacheable=true)
    public static TableWrapperCls getOfferDetailsOnNewVersion(id behaveOnUserId){

        list<OfferCls> offerClsLst = new list<offerCls>();
        TableWrapperCls tbr = new TableWrapperCls();
        try{
            list<contact> contList = new WosSelector().getContactOfferDetails(behaveOnUserId);
            tbr = findOfferDetailsOnChange(contList[0]?.account.PartnerOffer__r.Offer__c,contList[0]?.account.PartnerOffer__c,contList[0]?.accountid,true, behaveOnUserId); 
        }catch(Exception e){
            ErrorLogger errorLog = new ErrorLogger();
            errorLog.logException(e, Constants.GENERIC_ERRORLOG_RECORDTYPE, '', true); 
            throw new ErrorLogger.ErrorLoggerException('Some error happened while getting new version.', e);
        }
        return tbr;
    }

    /***
    Name: getDetailsForQuickCalculationScreen
    Purpose: to get the details like default offers,products, to pass to the calculation api from quick calculation screen
    **/
    @AuraEnabled(cacheable=true)
    public static TableWrapperCls getDetailsForQuickCalculationScreen(){
        
       //get the contact id of the current user
        list<contact> contList = new WosSelector().getContactOfferDetails(UserInfo.getUserId());     
        TableWrapperCls tbwr = new TableWrapperCls();
        tbwr.applicableOfferId = contList[0]?.account.PartnerOffer__c;  
        tbwr.offerCurency = contList[0]?.account?.PartnerOffer__r.Offer__r.CurrencyIsoCode;  
        tbwr.accountid = contList[0]?.accountid;  
        tbwr.offerPaymentFreqncy = contList[0]?.account?.PartnerOffer__r.Offer__r.Default_Payment_Frequency__c;
        tbwr.offerPaymentTiming = contList[0]?.account?.PartnerOffer__r.Offer__r.Default_Payment_Timing__c;
        tbwr.programId = contList[0]?.account?.PartnerOffer__r.Offer__r.Program__c;

        OfferCls offer = new OfferCls();
        offer.termsOption = contList[0]?.account?.PartnerOffer__r.Offer__r.Selectable_Quick_Calculation_Term__c;
        list<OfferCls> offClsList = new list<OfferCls>{offer};
        tbwr.offrcls = offClsList;

        return tbwr;
    }

    /***
    Name: createProductClass
    Purpose: create the product object
    **/
    private static ProductCls createProductClass(integer financeAmount){
        //create a product row on the page
        ProductCls prodcls = new ProductCls();
        prodcls.prodid = '';
        prodcls.prodName = '';
        prodcls.productType = '';
        prodcls.prodDesc ='';
        prodcls.quantity = '1';
        prodcls.unitPrice = financeAmount != null && financeAmount != 0 ? string.valueof(financeAmount) : '';
        prodcls.totalprice = financeAmount != null && financeAmount != 0 ? string.valueof(financeAmount) : '0';
        prodcls.operation = 'add';
        prodcls.quotelineid = '';
        
        return prodcls;
    }
   
    /*Name:getOfferDetails
    * Purpose: To show the default offers for logged in user on page load along with products and services
    */
    @AuraEnabled//(cacheable=true)
    public static TableWrapperCls getOfferDetails(string oppIdFromUrl, integer financeAmount, id behaveOnUserId){

        string latestQtNum = ''; //to hold the latest quote number on the oppty       
        string quoteidStr = '';
        String termStr = ''; //hold the default term
        string restQuotesStr = '';
        string latestQtStr = '';
        String newOppIdDirectlyOpen = ''; //new oppty id when quote calcualtion page directly opens
        Boolean appliedPR = false;
        Boolean disabledCalculationParams;
        
        decimal financeVal= 0.0;     
        decimal monthlyVal = 0.0;
        decimal baseRateVal = 0.0;
        decimal rentalAmount = 0.0;
        decimal nominalInterestRate = 0.0;
        decimal futureValue;
        decimal downpayment;
        //integer accumulatedServiceAmount = 0;

        boolean isQuotePresent = false; //flag to check if quote exists on an Opportunity or not
        boolean isQuoteCalScrnDirectlyOpened = false; //to check if the quote page opened by user directly from the create deal tab and the default offer is shown on ui.

        set<string> offerIds = new set<String>();

        list<OfferCls> offerClsLst = new list<OfferCls>();
        list<ProductCls> prdClsLst = new list<ProductCls>();
        list<ServiceCls> srvClsLst = new list<ServiceCls>();
        list<id> acctIdLst = new list<id>();
        list<QuoteLineItem> quoteLineItemList = new list<QuoteLineItem>();
        List<Opportunity> oppLst = new List<Opportunity>();
        List<Quote> quoteLst = new List<Quote>();
        list<ProdtoquoteCls> prodtoQuoteObjList = new list<ProdtoquoteCls>();
        List<ServicertoquoteCls> servicesInfoList = new list<ServicertoquoteCls>();

        SubmitAppWrapperCls subAddWrCls;

        //get the contact id of the current user and the default offer mapped to the account of the contact
        list<contact> contList = new WosSelector().getContactOfferDetails(behaveOnUserId);   
        offerIds.add(contList[0]?.account?.PartnerOffer__r.Offer__c);
        acctIdLst.add(contList[0]?.accountid); //taking the accountid to find the related oppty
    
        /*Scenario 1: User opened an existing opportunity  */      
        if(String.isNotBlank(oppIdFromUrl) && (financeAmount == 0 || financeAmount == null)){
            try{
                oppLst = new WosSelector().getOpportunities(oppIdFromUrl);
                //SOQL to get the related quote(s) on the opportunity
                quoteLst = new WosSelector().getQuotes(oppLst);
            }catch(Exception e){
                ErrorLogger errorLog = new ErrorLogger();
                errorLog.logException(e, Constants.GENERIC_ERRORLOG_RECORDTYPE, oppIdFromUrl, true); 
                throw new ErrorLogger.ErrorLoggerException('Some error happened while SOQL on Quote/Opportunity', e);
            }
            
            integer count = 1;
            if(quoteLst != NULL && quoteLst.size() > 0){
                baseRateVal = getBaseRateFromRate(string.valueof(contList[0].account.PartnerOffer__r.Offer__c),quoteLst[0].Term__c,quoteLst[0].Frequency__c.toLowerCase(),quoteLst[0].Interest__c);
             
                for(Quote eachQuote : quoteLst){
                    latestQtNum = quoteLst[0].QuoteNumber;  //to hold the latest quote number on the oppty
                    quoteidStr = quoteLst[0].id;
                    latestQtStr = quoteLst[0].Name;
                    termStr = quoteLst[0].Term__c; 
                    financeVal = quoteLst[0].Financed_Amount__c;
                    rentalAmount = quoteLst[0].Rental_Amount__c;
                    nominalInterestRate = quoteLst[0].Nominal_Interest_Rate__c;
                    isQuotePresent = true;                  
                    restQuotesStr +=  eachQuote.IsSyncing 
                        ? Constants.SPECIALCHAR1+' '+eachQuote.Name+'='+eachQuote.id+Constants.SPECIALCHAR2+eachQuote.QuoteNumber+';' 
                        : eachQuote.Name+'='+eachQuote.id+Constants.SPECIALCHAR2+eachQuote.QuoteNumber+';'; 
                    count++;
                    futureValue = (quoteLst[0].Future_Value__c != null) ? quoteLst[0].Future_Value__c : futureValue;
                    downpayment = (quoteLst[0].Downpayment__c != null) ? Decimal.valueOf(quoteLst[0].Downpayment__c) : downpayment;
                    appliedPR =  quoteLst[0].Applied_Purchase_Option__c ;
                    disabledCalculationParams = quoteLst[0].Disabled_Calculation_Params__c;
                   // why we itreate if we need only 1st row break;
                }
            }      
            restQuotesStr = String.isNotBlank(restQuotesStr) ? restQuotesStr.removeEnd(';') : '';         
        }else {
                /*Scenario 1: when the user directly opens the quote calculation screen to create Opportunity from create deal tab. 
                * scenario:2 : US449018 Initiate deal Without the value from quick calculation .
                * Scenario 3: user clicks on create deal from quick cal screen 
                */
                //TableWrapperCls tbwr = getDetailsForQuickCalculationScreen();
                //create opportunity only when oppty id is not there             
                newOppIdDirectlyOpen = String.isBlank(oppIdFromUrl) ? createOpportunity(0.0,contList[0].accountid,contList[0].account.PartnerOffer__r.Offer__r.CurrencyIsoCode, behaveOnUserId) : oppIdFromUrl; 
                isQuoteCalScrnDirectlyOpened = true;
                //create the offer table         
                offerClsLst.add(createOfferObj(new list<Quote>(), contList));
                baseRateVal = getBaseRateFromRate(string.valueof(contList[0].account.PartnerOffer__r.Offer__c),contList[0].account.PartnerOffer__r.Offer__r.Default_Agreement_Term__c,contList[0].account.PartnerOffer__r.Offer__r.Default_Payment_Frequency__c.toLowerCase(),contList[0].account.PartnerOffer__r.Offer__r.Default_Base_Rate__c);
                prdClsLst.add(createProductClass(financeAmount));                  
        }         

        //if quote is present on a opportunity
        if(isQuotePresent){
            //create the offer table           
            offerClsLst.add(createOfferObj(quoteLst,new list<contact>()));
            //find the related quote and quoteline items to the opportunity           
            list<QuoteLineItem> quoteLineItemLst = new WosSelector().getQuoteLineDetails(quoteidStr);
            //map of quotenumber to list of quotelineitem 
            map<string,list<QuoteLineItem>> quoteNumtoQuoteLineMap = new map<string,list<QuoteLineItem>>();
            if(quoteLineItemLst != null && quoteLineItemLst.size() > 0){
                for(QuoteLineItem eachLine : quoteLineItemLst){
                    if(quoteNumtoQuoteLineMap != null && quoteNumtoQuoteLineMap.containsKey(eachLine.Quote.QuoteNumber) && quoteNumtoQuoteLineMap.get(eachLine.Quote.QuoteNumber) != null){
                        list<QuoteLineItem> quotelineLst = quoteNumtoQuoteLineMap.get(eachLine.Quote.QuoteNumber);
                        quotelineLst.add(eachLine);
                        quoteNumtoQuoteLineMap.put(eachLine.Quote.QuoteNumber,quotelineLst);
                    }else{
                        quoteNumtoQuoteLineMap.put(eachLine.Quote.QuoteNumber,new list<QuoteLineItem>{eachLine});
                    }
                }            
            } 
            
            // map stores Product Id as a key and Asset Program Detail record as a value
            Map<Id,Asset_Program_Detail__c> offrPrdMap = new WoSSelector().getProductsFromProgram(offerClsLst[0].offerid, '');
                    
            if(quoteNumtoQuoteLineMap != NULL && quoteNumtoQuoteLineMap.size() > 0 && quoteNumtoQuoteLineMap.containsKey(latestQtNum) && quoteNumtoQuoteLineMap.get(latestQtNum) != NULL){
                list<QuoteLineItem> latestQuoteLineList = quoteNumtoQuoteLineMap.get(latestQtNum);
                for(QuoteLineItem eachLine : latestQuoteLineList){
                    if(eachLine.Product2.Family == 'Maintenance'){
                        ServiceCls srvCls = new ServiceCls();
                        srvCls.serviceId = eachLine.Product2id;
                        srvCls.serviceName = eachLine.Product2.name;
                        srvCls.productType = eachLine.Product2.Family;
                        srvCls.serviceDesc = eachLine.Product2.Description;
                        srvCls.quantity = string.valueof(integer.valueof(eachLine.Quantity));
                        srvCls.unitPrice = string.valueof(integer.valueof(eachLine.UnitPrice));
                        srvCls.totalprice = string.valueof(integer.valueof(eachLine.TotalPrice));
                        srvCls.operation = 'none';
                        srvCls.quotelineid = eachLine.id;
                        srvCls.isProductAvailable = offrPrdMap.get(eachLine.Product2id).Is_Active__c;
                        monthlyVal += eachLine.TotalPrice;
                        //accumulatedServiceAmount += eachLine.Maintenance_Amount__c != null ? integer.valueof(eachLine.Maintenance_Amount__c) : 0;
                        srvClsLst.add(srvCls);
                        ServicertoquoteCls serviceInfo = new ServicertoquoteCls(
                            String.valueof(eachLine.Quantity),
                            String.valueof(eachLine.UnitPrice),
                            String.valueof(eachLine.TotalPrice),
                            eachLine.Product2.name
                        );
                        servicesInfoList.add(serviceInfo);
                    }else if (eachLine.Product2.Family != 'ITAD') {
                        ProductCls prodcls = new ProductCls();
                        prodcls.prodid = eachLine.Product2id;
                        prodcls.prodName = eachLine.Product2.name;
                        prodcls.productType = eachLine.Product2.Family;
                        prodcls.prodDesc = String.isNotBlank(eachLine.Description) ? eachLine.Description : '';                                           
                        prodcls.quantity = string.valueof(integer.valueof(eachLine.Quantity));
                        prodcls.unitPrice = string.valueof(integer.valueof(eachLine.UnitPrice));
                        prodcls.totalprice = string.valueof(integer.valueof(eachLine.TotalPrice));
                        prodcls.operation = 'none';
                        prodcls.quotelineid = eachLine.id;
                        prodcls.isProductAvailable = offrPrdMap.get(eachLine.Product2id).Is_Active__c;
                        prodcls.insuranceRate = String.valueOf(eachLine.Insurance_Rate__c);
                        prodcls.rvRate = String.valueOf(eachLine.Residual_Value_Rate__c);
                        prodcls.isPurchaseOptionAvailable = eachLine.Residual_Value_Rate__c != null ? true : false ;
                        prodcls.isInsuranceAvailable = eachLine.Insurance_Rate__c != null ? true : false;
                        prdClsLst.add(prodcls);
                        ProdtoquoteCls prodtoQuoteObj = new ProdtoquoteCls(
                            String.valueof(eachLine.Quantity),
                            String.valueof(eachLine.UnitPrice),
                            String.valueof(eachLine.TotalPrice),
                            eachLine.Product2.name, 
                            eachLine.Description,
                            eachLine.Product2.Family,
                            String.valueOf(eachLine.Insurance_Rate__c),
                            String.valueOf(eachLine.Residual_Value_Rate__c)
                        );
                        prodtoQuoteObjList.add(prodtoQuoteObj);
                    } 
                }
            }
        }
    
        TableWrapperCls tbr = new TableWrapperCls();
        tbr.partnerName = contList[0]?.Name;
        tbr.partnerEmail = contList[0].Email != null ? contList[0].Email : '';
        tbr.twCurrentUserLocale = currentUserLocale;  
        tbr.accountRegionCode = contList[0].account.Account_Region_Code__c;
        tbr.offrcls = offerClsLst;
        tbr.prdCls = prdClsLst;
        tbr.srvCls = srvClsLst;
        tbr.baseRate = string.valueof(baseRateVal);      
        if(oppLst != null && oppLst.size() > 0)
            tbr.opptyName = oppLst[0]?.name;
        tbr.viewRentPerMonth = viewRentPerMonth;
        tbr.quoteid = quoteidStr;
        if(quoteLst != null && quoteLst.size() > 0){
            tbr.quoteStatus = quoteLst[0].Status;
            tbr.validTo = quoteLst[0]?.Valid_To__c;
            tbr.validFrom = quoteLst[0]?.Valid_From__c;
            tbr.isDocumentQstnExist = new WosSelector().getDocumentQuestionares(quoteLst[0].Status,quoteidStr);
            tbr.insuranceAmount = integer.valueof(quoteLst[0]?.Insurance_Amount__c);
            tbr.accumulatedService = integer.valueof(quoteLst[0]?.Accumulated_Service__c);
        }        
        tbr.totalFinanceVal = integer.valueof(financeVal);
        tbr.totalMonthlyVal = string.valueof(monthlyVal);    
        tbr.rentalVal = integer.valueof(rentalAmount);  
        tbr.futureValue = futureValue;
        tbr.downpayment = downpayment; 
        tbr.appliedPR = appliedPR;
        tbr.disabledCalculationParams = disabledCalculationParams;
        
        tbr.nominalInterestRate = string.valueof(nominalInterestRate);
        //to hold the rest quote names
        tbr.restQuotes = restQuotesStr;
        tbr.latestQuote = latestQtStr;
        tbr.opportunityId = String.isNotBlank(oppIdFromUrl) ? oppIdFromUrl : newOppIdDirectlyOpen;
        if(isQuoteCalScrnDirectlyOpened){
            tbr.newOppIdWhenQtPgDirectlyOpen = newOppIdDirectlyOpen;
            tbr.opptyName = new WosSelector().getOpportunities(newOppIdDirectlyOpen)[0].name;
        }
        //for submit application request details
        if(quoteLst != null && quoteLst.size() > 0 && oppLst != null && oppLst.size() > 0){
            subAddWrCls = new SubmitAppWrapperCls(
                oppLst[0].Owner.Name,
                quoteLst[0].Applicable_Offers__r.Offer__r.Program__r.Business_Unit__r.Name,
                string.valueof(oppLst[0].CreatedDate),
                quoteLst[0].Applicable_Offers__r.name,
                quoteLst[0].Applicable_Offers__r.Offer__r.name,
                oppLst[0].CurrencyIsoCode,
                quoteLst[0].Term__c,
                quoteLst[0].Frequency__c,
                quoteLst[0].Payment_Timing__c,
                string.valueof(quoteLst[0].Financed_Amount__c),
                string.valueof(quoteLst[0].Nominal_Interest_Rate__c),
                prodtoQuoteObjList ,
                servicesInfoList,
                ''
            );
        }        
        tbr.submitAddWrapper = subAddWrCls;
        
        return tbr;
    }

    /**
    *Name: getBaseRateFromRate
    *Purpose: to find the base rate from rate line item
     */
    @AuraEnabled(cacheable=true)
    public static decimal getBaseRateFromRate(string offerIdStr, string term, string frequency, string interest){
        
        string fixedBaseRateId = '';
        string variableBaseRateId = '';
        decimal baseRate = 0.0;
        List<Rate_Line_Item__c> rateLineItemList;

        list<offer__c> offerList = new WosSelector().getOfferRecordDetails(offerIdStr); //qeury the offer record
        string termValue = getNextHighestTerm(offerList[0].Selectable_Agreement_Term__c,term);
        
        if(interest == Constants.FIXED_RATE_TYPE){
            fixedBaseRateId = offerList[0].Base_Rate_Fixed__c;
        }else if(interest == Constants.VARIABLE_RATE_TYPE){
            variableBaseRateId = offerList[0].Base_Rate_Variable__c;
        } 
        string rateLineItemQuery = 'SELECT id,Term__c,Rate_Value__c,Term__r.Term_Value__c FROM Rate_Line_Item__c ';
        if(String.isNotBlank(fixedBaseRateId)){
            rateLineItemQuery += ' WHERE Rate__c =\''+ String.escapeSingleQuotes(fixedBaseRateId)+'\'';
        }else if(String.isNotBlank(variableBaseRateId)){
            rateLineItemQuery += ' WHERE Rate__c = \''+ String.escapeSingleQuotes(variableBaseRateId)+'\'';
        }
        
        try{
            rateLineItemList = (List<Rate_Line_Item__c>)new WosSelector().getRecordsList(rateLineItemQuery);
        }catch(Exception e){
            ErrorLogger errorLog = new ErrorLogger();
            errorLog.logException(e, Constants.GENERIC_ERRORLOG_RECORDTYPE, offerIdStr, true); 
            throw new ErrorLogger.ErrorLoggerException('Some error happened while Quering Base rate.', e);   
        }
           
        map<string,integer> paymentFrqncyMap = new map<string,integer>{'monthly'=>30,'quarterly'=>90,'semi-annually'=>180,'annually'=>360}; 
        
        if(rateLineItemList != null && rateLineItemList.size() > 0){
            for(Rate_Line_Item__c eachRateLine : rateLineItemList){
                //for fixed interest rate
                if(interest == Constants.FIXED_RATE_TYPE && termValue == string.valueof(eachRateLine.Term__r.Term_Value__c)){
                    baseRate = eachRateLine.Rate_Value__c;
                }else if(interest == Constants.VARIABLE_RATE_TYPE && paymentFrqncyMap.containsKey(frequency) && paymentFrqncyMap.get(frequency) == eachRateLine.Term__r.Term_Value__c ){
                    //for variable interest rate
                    baseRate = eachRateLine.Rate_Value__c;
                }
            }
        }
        return baseRate;
    }

    /***
    *Name: findOfferDetailsOnChange
    *Purpose: when offer changes on the existing quote, delete all the quote lineitems on it and then insert all new prods/services for this
             Get the existing quoteline of the quote and delete all, need to handle in apex for deletion  
    **/
    @AuraEnabled(cacheable=true)
    public static TableWrapperCls findOfferDetailsOnChange(string offeridstr, string applicableOfferId, string accountId, boolean isNewVersion, id behaveOnUserId){
        decimal baseRateVal = 0.0;
        set<string> offerIds = new set<String>();
        list<OfferCls> offerClsLst = new list<OfferCls>();
        list<ProductCls> prdClsLst = new list<ProductCls>();
        list<ServiceCls> srvClsLst = new list<ServiceCls>();
        list<offer__c> offerList = new list<offer__c>();
        list<contact> contList;

        try{
            contList = new WosSelector().getContactOfferDetails(behaveOnUserId);
            baseRateVal = getBaseRateFromRate(string.valueof(contList[0].account.PartnerOffer__r.Offer__c),contList[0].account.PartnerOffer__r.Offer__r.Default_Agreement_Term__c,contList[0].account.PartnerOffer__r.Offer__r.Default_Payment_Frequency__c.toLowerCase(),contList[0].account.PartnerOffer__r.Offer__r.Default_Base_Rate__c);              
            //find the applicable offer id if blank
            if(String.isBlank(applicableOfferId)){
                //Applicable_Offer__c appOfferId = new WosSelector().getApplicableOfferByAccount(contList,offeridstr);
                applicableOfferId = new WosSelector().getApplicableOfferByAccount(contList,offeridstr).id;
            }         
           
            offerList = new WosSelector().getOfferRecordDetails(offeridstr);
        }catch(Exception e){
            ErrorLogger errorLog = new ErrorLogger();
            errorLog.logException(e, Constants.GENERIC_ERRORLOG_RECORDTYPE, offerIdStr, true);       
        }
        
        for(offer__c ofr : offerList){
            OfferCls offer = new OfferCls();
            offer.offerid = ofr.id;  
            offer.offerName = ofr.Name;  
            offer.termsOption = ofr.Selectable_Agreement_Term__c;                            
            offer.defaultTerm = ofr.Default_Agreement_Term__c; 
            offer.freqOptions = ofr.Selectable_Payment_Frequency__c;  
            offer.defaultFreq = ofr.Default_Payment_Frequency__c;  
            offer.intOptions = ofr.Selectable_Base_Rate__c == 'Both' ? Constants.str_Rate_Value : ofr.Selectable_Base_Rate__c; 
            offer.defaultInt = ofr.Default_Base_Rate__c;
            offer.defaultcurncy = ofr.CurrencyIsoCode;
            offer.paymentTiming = ofr.Default_Payment_Timing__c;
            offer.programId = ofr.Program__c;
            offer.applicableOfferId = applicableOfferId;
            offer.isItadApplicable = ofr.Is_ITAD_Applicable__c;
            offer.rvType = ofr.RV_Type__c;
            offer.termRange = ofr.Include_Term_Range_Values__c;
            offerClsLst.add(offer);
         
            offerIds.add(ofr?.id);
            
        }
        prdClsLst.add(createProductClass(0)); 
        TableWrapperCls tbr = new TableWrapperCls();
        tbr.offrcls = offerClsLst;
        tbr.prdCls = prdClsLst;
        tbr.totalFinanceVal = 0;
        tbr.rentalVal = 0;
        tbr.totalMonthlyVal = '0';
        tbr.accumulatedService = 0;
        tbr.baseRate = string.valueof(baseRateVal);
        tbr.viewRentPerMonth = viewRentPerMonth;
        tbr.accountRegionCode = contList[0]?.account.Account_Region_Code__c;
        return tbr;
    }
  
    /**
    *Name:doSaveQuoteDetail
    *Purpose: Used to insert/update quote
     */
    @AuraEnabled
    public static SubmitAppWrapperCls doSaveQuoteDetail(string offeridstr,string productdetails,string servicedetails,string quoteid,string quoteAmountRateDetails,boolean isNewVer, list<string> deleteLineLst,string opptyId,id behaveOnUserId){     
        
        string newQuoteDetailsStr = '';
        string currentQuoteId = '';
        SubmitAppWrapperCls subAddWrCls = new SubmitAppWrapperCls();
        list<QuoteLineItem> newQuoteLineItemList = new list<QuoteLineItem>();
        list<QuoteLineItem> updateQuoteLineItemList = new list<QuoteLineItem>();
        list<QuoteLineItem> deleteQuoteLineItemList = new list<QuoteLineItem>();
        List<ProdtoquoteCls> prodlist;
        List<ServicertoquoteCls> servicelist;
        OffertoQuoteCls ofrDesrialize;
        QuoteFinanceRateAmountCls quoteAmountsDeserialize;

        // if calculation params are updated by Internal DLL Member, partner can't update these values  
        Boolean disabledCalculationParams = UserInfo.getUserId() != behaveOnUserId;
        
        try{
            string replaceOfrStr = offeridstr.replace('Offer__c','offerId');     
            ofrDesrialize = (OffertoQuoteCls)System.JSON.deserialize(replaceOfrStr, OffertoQuoteCls.class);
            string replaceProd1 = productdetails.replace('"Product":[','"Product":');
            string replaceProdStr = replaceProd1.replace('],"specification',',"specification');
            prodlist = (List<ProdtoquoteCls>) System.JSON.deserialize(replaceProdStr, List<ProdtoquoteCls>.class);  
        
            string replaceServ1 = servicedetails.replace('"Product":[','"Product":');
            string replaceServStr = replaceServ1.replace('],"quantity',',"quantity');
            servicelist = (List<ServicertoquoteCls>) System.JSON.deserialize(replaceServStr, List<ServicertoquoteCls>.class);
           
            //get the finacne amount, rental amount, nominal interest rate:
            quoteAmountsDeserialize = (QuoteFinanceRateAmountCls)System.JSON.deserialize(quoteAmountRateDetails, QuoteFinanceRateAmountCls.class);
        }catch(Exception e){
            ErrorLogger errorLog = new ErrorLogger();
            errorLog.logException(e, Constants.GENERIC_ERRORLOG_RECORDTYPE, ofrDesrialize?.offerId, true);  
            throw new ErrorLogger.ErrorLoggerException( 'Some error happened while getting deserializing JSON.', e);             
        }       
        /******if quote is there update the quote and line item, if not quote present, create a new quote with the line items*****/
        if(String.isNotBlank(quoteid)){
            List<Quote> existingQuote = new WosSelector().queryQuoteDetails(quoteid);
           //SOQL on quote lineitem for the given quote id
            list<QuoteLineItem> quoteLineItemLst = new WosSelector().getQuoteLineDetails(quoteId);
           //SQOl on appliacble offer to get the id depending on the offer id
            Applicable_Offer__c apf = new Applicable_Offer__c();
            if(String.isNotBlank(ofrDesrialize.offerId)) 
                apf = new WosSelector().getApplicableOffer(ofrDesrialize.offerId);
            
            existingQuote[0].Applicable_Offers__c = apf.id;
            //create 3 new fields to update on quote, code goes below
            existingQuote[0].Term__c = ofrDesrialize.term;
            existingQuote[0].Interest__c = ofrDesrialize.interest;           
            existingQuote[0].Frequency__c = ofrDesrialize.frequency;
            existingQuote[0].Payment_Timing__c = ofrDesrialize.paymentTiming;
            existingQuote[0].Quote_Rate__c = ofrDesrialize.interest == Constants.VARIABLE_RATE_TYPE ? apf.Offer__r.Base_Rate_Variable__c : apf.Offer__r.Base_Rate_Fixed__c ;
            existingQuote[0].Status = Constants.QUOTE_CALCULATION_STATUS;
            existingQuote[0].ITAD_Category__c = ofrDesrialize.itadLevel;
            existingQuote[0].Insurance_Amount__c = ofrDesrialize.insurancePayments;
            existingQuote[0].Accumulated_Service__c = ofrDesrialize.accumulatedService;
            existingQuote[0].OwnerId = behaveOnUserId;
            existingQuote[0].Rent_Per_Month__c = ofrDesrialize.viewRentPerMonth;
            existingQuote[0].Applied_Purchase_Option__c = ofrDesrialize.purchaseOption == 'true' ? true :false;
            existingQuote[0].Disabled_Calculation_Params__c = disabledCalculationParams;
            
            
            if(quoteAmountsDeserialize.financeAmount != null)
                existingQuote[0].Financed_Amount__c = Decimal.valueof(quoteAmountsDeserialize.financeAmount);
            if(quoteAmountsDeserialize.rentalAmount != null)
                existingQuote[0].Rental_Amount__c = Decimal.valueof(quoteAmountsDeserialize.rentalAmount);
            if(quoteAmountsDeserialize.nominalInterestRate != null)
                existingQuote[0].Nominal_Interest_Rate__c = Decimal.valueof(quoteAmountsDeserialize.nominalInterestRate);
                if(quoteAmountsDeserialize.futureValue != null)
                existingQuote[0].Future_Value__c = Decimal.valueof(quoteAmountsDeserialize.futureValue);  

            if(existingQuote != null){
                try{
                  
                    new GenericUtilityClass.WoSDMLProcessor().updateRecords(existingQuote); 
                }catch(Exception e){
                    ErrorLogger errorLog = new ErrorLogger();
                    errorLog.logException(e, Constants.GENERIC_ERRORLOG_RECORDTYPE, existingQuote[0].Id, true);  
                    throw new ErrorLogger.ErrorLoggerException( 'Some error happened while getting upating quote:', e);   
                }             
            }
          
            /***Handle quote line item**/
            createQuoteLineItem(prodlist,servicelist,newQuoteLineItemList,existingQuote[0]);
            updateQuoteLineItemList = updateQuoteLineItem(prodlist,servicelist,quoteLineItemLst,existingQuote[0],ofrDesrialize.operation);
            
            subAddWrCls = new SubmitAppWrapperCls(
                existingQuote[0].Opportunity.Owner.Name,
                existingQuote[0].Applicable_Offers__r.Offer__r.Program__r.Business_Unit__r.Name,
                string.valueof(existingQuote[0].Opportunity.CreatedDate),
                existingQuote[0].Applicable_Offers__r.name,
                existingQuote[0].Applicable_Offers__r.Offer__r.name,
                existingQuote[0].Opportunity.CurrencyIsoCode,
                existingQuote[0].Term__c,
                existingQuote[0].Frequency__c,
                existingQuote[0].Applicable_Offers__r.Offer__r.Default_Payment_Timing__c,
                string.valueof(existingQuote[0].Financed_Amount__c),
                string.valueof(existingQuote[0].Nominal_Interest_Rate__c),
                prodlist,
                servicelist,
                ''
            );
            
                
            if(deleteLineLst != null && deleteLineLst.size() > 0){
                //deleteQuoteLineItemList.add
                for(string eachStr : deleteLineLst){
                    QuoteLineItem q = new QuoteLineItem(id = id.valueOf(eachStr));
                    deleteQuoteLineItemList.add(q);
                }
            }

            try{
                if(newQuoteLineItemList.size() > 0){
                    //insert newQuoteLineItemList; //insert new quote line item
                    new GenericUtilityClass.WoSDMLProcessor().insertRecords(newQuoteLineItemList); 
                }
                if(updateQuoteLineItemList.size() > 0){
                    //update updateQuoteLineItemList; //update existing quote line items
                    new GenericUtilityClass.WoSDMLProcessor().updateRecords(updateQuoteLineItemList); 
                }
                if(deleteQuoteLineItemList.size() > 0){
                    //delete deleteQuoteLineItemList; //delete quote line item
                    new GenericUtilityClass.WoSDMLProcessor().deleteRecords(deleteQuoteLineItemList); 
                }
            }catch(Exception e){
                ErrorLogger errorLog = new ErrorLogger();
                errorLog.logException(e, Constants.GENERIC_ERRORLOG_RECORDTYPE, existingQuote[0].id, true);  
                throw new ErrorLogger.ErrorLoggerException( 'Some error happened while upating new version.', e);                           
            }
        }
        //When user clicks on New button,a new Quote will be created
        //when new quote needs to be created on click of 'select customer' button
        else if(String.isBlank(quoteid)){ //&& isNewVer
             //SQOl on applicable offer to get the id depending on the offer id
            Applicable_Offer__c apf = new Applicable_Offer__c();
            List<Opportunity> oppLst = new List<Opportunity>();
            Quote newQuote = new Quote();
             if(String.isNotBlank(ofrDesrialize.offerId)){
                  apf = new WosSelector().getApplicableOffer(ofrDesrialize.offerId);
             }
            oppLst = new WosSelector().getOppAndQuoteList(opptyId);    
            if(oppLst != null && oppLst.size() > 0){
                newQuote.Name = 'Version-'+getLatestQuoteVersion(oppLst[0].Quotes);
            }             
            newQuote.OpportunityId = oppLst[0].id;  //when there are more than 1 oppty, which one to take????
            newQuote.CurrencyIsoCode = oppLst[0].CurrencyIsoCode;
            newQuote.Applicable_Offers__c = apf.id;
            newQuote.Pricebook2Id = oppLst[0].Pricebook2.Id;
            //3new fields need to be updated, code below
            newQuote.Term__c = ofrDesrialize.term;
            newQuote.Interest__c = ofrDesrialize.interest;           
            newQuote.Frequency__c = ofrDesrialize.frequency;
            newQuote.Payment_Timing__c = ofrDesrialize.paymentTiming;
            newQuote.ITAD_Category__c = ofrDesrialize.itadLevel;
            newQuote.Insurance_Amount__c = ofrDesrialize.insurancePayments;
            newQuote.Accumulated_Service__c = ofrDesrialize.accumulatedService;
            newQuote.Quote_Rate__c = ofrDesrialize.interest == Constants.VARIABLE_RATE_TYPE ? apf.Offer__r.Base_Rate_Variable__c : apf.Offer__r.Base_Rate_Fixed__c;
            newQuote.Status = Constants.QUOTE_CALCULATION_STATUS; //first status of quote when created
            newQuote.OwnerId = behaveOnUserId;
            newQuote.Applied_Purchase_Option__c = ofrDesrialize.purchaseOption == 'true' ? true :false;
            newQuote.Rent_Per_Month__c = ofrDesrialize.viewRentPerMonth;
            newQuote.Disabled_Calculation_Params__c = disabledCalculationParams;
            if(quoteAmountsDeserialize.financeAmount != null)
                newQuote.Financed_Amount__c = Decimal.valueof(quoteAmountsDeserialize.financeAmount);
            if(quoteAmountsDeserialize.rentalAmount != null)
                newQuote.Rental_Amount__c = Decimal.valueof(quoteAmountsDeserialize.rentalAmount);
            if(quoteAmountsDeserialize.nominalInterestRate != null)
                newQuote.Nominal_Interest_Rate__c = Decimal.valueof(quoteAmountsDeserialize.nominalInterestRate);
            if(quoteAmountsDeserialize.futureValue != null)
                newQuote.Future_Value__c = Decimal.valueof(quoteAmountsDeserialize.futureValue);
            //quote and oppty currecny shud match         
            try{
                if(newQuote != null){
                    //insert newQuote; //dml on quote  
                    new GenericUtilityClass.WoSDMLProcessor().insertRecords(new list<quote>{newQuote});      
                    Quote newQuoteDetails = new WosSelector().getQuoteById(newQuote);
                    newQuoteDetailsStr = newQuoteDetails.Name+'='+newQuote.id+Constants.SPECIALCHAR2+newQuoteDetails.QuoteNumber+';'; 
                    subAddWrCls.newQuoteDetailsStr = newQuoteDetailsStr;
                }  
            }catch(Exception e){
                ErrorLogger errorLog = new ErrorLogger();
                errorLog.logException(e, Constants.GENERIC_ERRORLOG_RECORDTYPE, '', true); 
                throw new ErrorLogger.ErrorLoggerException( 'Some error happened while DML operation.', e);                
            }  

            /**Handle quote line item**/
            createQuoteLineItem(prodlist,servicelist,newQuoteLineItemList,newQuote);
            subAddWrCls = new SubmitAppWrapperCls(
                oppLst[0].Owner.Name,
                apf.Offer__r.Program__r.Business_Unit__r.Name ,
                string.valueof(oppLst[0].CreatedDate),
                apf.name,
                apf.Offer__r.name,
                oppLst[0].CurrencyIsoCode,
                ofrDesrialize.term,
                ofrDesrialize.frequency,
                ofrDesrialize.paymentTiming,
                quoteAmountsDeserialize.financeAmount,
                quoteAmountsDeserialize.nominalInterestRate,
                prodlist,
                servicelist,
                newQuoteDetailsStr
            );        
            try{
                if(newQuoteLineItemList.size() > 0){
                   //insert newQuoteLineItemList;
                    new GenericUtilityClass.WoSDMLProcessor().insertRecords(newQuoteLineItemList); 
                }                   
            }catch(Exception e){
                ErrorLogger errorLog = new ErrorLogger();
                errorLog.logException(e, Constants.GENERIC_ERRORLOG_RECORDTYPE, newQuote.id, true); 
                throw new ErrorLogger.ErrorLoggerException( 'Some error happened while DML operation.', e);   
            }           
        }     
        
        //subAddWrCls.appliedPR = ofrDesrialize.purchaseOption == 'true' ? true :false;
        
        return subAddWrCls; //return only in case of newly created quote, for upadte return blank
    }

    /*
    *Name: getLatestQuoteVersion
    *Purpose: to get the version number from the quote name
    */
    @TestVisible
    private static integer getLatestQuoteVersion(List<Quote> quotes){
        
        integer lastQuoteNum = 1;
        //iterating to get the last create quote name, if no quote is present , keep name as version1 for this oppty
        if(quotes != NULL && quotes.size() > 0){
            //get the version number after '-'
            lastQuoteNum = integer.valueof(quotes[0].Name.substringAfterLast('-'));
            lastQuoteNum++;
        }
        return lastQuoteNum;
    }

     /**
    *Name:getPriceBookEntry
    *Purpose: get the PriceBookEntry details for a product and quote lines
     */
    public static map<id,PricebookEntry> getPriceBookEntry(List<ProdtoquoteCls> prodlist,List<ServicertoquoteCls> servicelist,Quote existingQuote){
        
        set<id> product2idSet = new set<id>();
        map<id,PricebookEntry> product2PeMap = new map<id,PricebookEntry>();

      //get the product2id
        for(ProdtoquoteCls eachProd : prodlist){
            if(eachProd.product != null && eachProd.product != '')
                product2idset.add(eachProd.product);
        }
        for(ServicertoquoteCls eachProd : servicelist){
            if(eachProd.product != null && eachProd.product != '')
                product2idset.add(eachProd.product);
        }

        try{
            //to get the pricebook entry id according to quote currency used while inserting quoteline item
            for(PricebookEntry pe : new WosSelector().getPbeList(product2idSet,existingQuote)){
                product2PeMap.put(pe.Product2Id,pe);
            }
        }catch(Exception e){
            ErrorLogger errorLog = new ErrorLogger();
            errorLog.logException(e, Constants.GENERIC_ERRORLOG_RECORDTYPE, existingQuote.id, true); 
            throw new ErrorLogger.ErrorLoggerException( 'Some error happened while getting Pricebookentry', e);                       
        }
        
        return product2PeMap;
    }
  
     /**
    *Name:getItadCalculation
    *Purpose: get the ITAD calcualtion for a quote and its products
     */
    private static Map<string,double> getItadCalculation(Quote existingQuote,List<ProdtoquoteCls> prodlist){

        Map<string,integer> productNameToQuantityMap = new Map<string,integer>();
        list<Asset_Program_Detail__c> assetProgDetailList = new WosSelector().getAssetProgramDetails(existingQuote);
        for(Asset_Program_Detail__c eachDetail : assetProgDetailList){
            if(eachDetail.ITAD_Product__c != NULL){ 
                prodIdToItadProdNameMap.put(eachDetail.Product__c,eachDetail.ITAD_Product__r.Name);
            }               
        }
       
        for(ProdtoquoteCls eachProd : prodlist){
            if(String.isNotBlank(eachProd.product)){
                productNameToQuantityMap.put(eachProd.productname.toLowerCase(),integer.valueof(eachProd.Quantity));
            }
        }
        
        //get ITAD calculation value
        List<CalculationRequestBodyWrapper.FeesWrapperClass> itadFees = ((CalculationRequestBodyWrapper.findItadApplicableInOffer(offer_programId,existingQuote.Applicable_Offers__c,productNameToQuantityMap,existingQuote.ITAD_Category__c)) != null 
                                                                        ? (CalculationRequestBodyWrapper.findItadApplicableInOffer(offer_programId,existingQuote.Applicable_Offers__c,productNameToQuantityMap,existingQuote.ITAD_Category__c)) 
                                                                        : new List<CalculationRequestBodyWrapper.FeesWrapperClass>());
        
        //find total ITAD amount      
        for(CalculationRequestBodyWrapper.FeesWrapperClass eachItad : itadFees){
            double periodicAmount = eachItad.amount/integer.valueof(existingQuote.Term__c); //find the periodic amount
            double eachItadProductPrice = periodicAmount/eachItad.quantity; //find each itad product price
            //itadProdNameToPriceMap.put(eachItad.id,eachItadProductPrice.round());
            itadProdNameToPriceMap.put(eachItad.id,eachItadProductPrice);
        }

        return itadProdNameToPriceMap;
    }

     /**
    *Name:createQuoteLineItem
    *Purpose: Utility method to create quote line items for a given quote
     */
    public static void createQuoteLineItem(List<ProdtoquoteCls> prodlist,List<ServicertoquoteCls> servicelist, List<QuoteLineItem> newQuoteLineItemList,Quote existingQuote){
        
        set<id> assetDetailsIdSet = new set<id>();
        map<id,PricebookEntry> product2PeMap = getPriceBookEntry(prodlist,servicelist,existingQuote);
        getItadCalculation(existingQuote,prodlist);

        for(ProdtoquoteCls eachProd : prodlist){
            if(String.isNotBlank(eachProd.product)){
                assetDetailsIdSet.add(eachProd.assetModelId);
            }
        }
        map<string,Asset_Program_Detail__c> assetProgramDetailsMap =  new WosSelector().getAssetProgramLineRecords(assetDetailsIdSet);

        integer count = 1;
        for(ProdtoquoteCls eachProd : prodlist){
            if(String.isNotBlank(eachProd.product)){
                //for insert Primary__c            
                if(eachProd.operation == 'add'){
                    QuoteLineItem newQuoteLineItem = new QuoteLineItem();
                    newQuoteLineItem.Primary__c = count == 1 
                                                ? true  
                                                : false;              
                    string itadProductName = (!prodIdToItadProdNameMap.isEmpty() && prodIdToItadProdNameMap.containskey(eachProd.product) && (prodIdToItadProdNameMap.get(eachProd.product) != null)) 
                                                ? prodIdToItadProdNameMap.get(eachProd.product) : 
                                                '';                       
                                                      
                    newQuoteLineItem.ITAD_Fee__c = (itadProdNameToPriceMap.containskey(itadProductName.toLowerCase()) && itadProdNameToPriceMap.get(itadProductName.toLowerCase()) != null)
                                                    ? ((integer.valueof(eachProd.Quantity) * itadProdNameToPriceMap.get(itadProductName.toLowerCase())).round()) 
                                                    : 0;
                    newQuoteLineItem.Product2Id = eachProd.product;
                    newQuoteLineItem.Description = eachProd.specification ;                 
                    newQuoteLineItem.Quantity = String.isNotBlank(eachProd.Quantity) ? integer.valueof(eachProd.Quantity) : 1;                 
                    newQuoteLineItem.QuoteId = existingQuote.id;                
                    newQuoteLineItem.UnitPrice = String.isNotBlank(eachProd.UnitPrice) 
                        ? integer.valueof(eachProd.UnitPrice)               
                        : 1;
                   
                    if(product2PeMap != null && product2PeMap.containskey(eachProd.product) && product2PeMap.get(eachProd.product).id != null)
                        newQuoteLineItem.PricebookEntryId  = product2PeMap.get(eachProd.product).Id;
                    
                    newQuoteLineItem.Residual_Value_Rate__c = eachProd.residualValue; 
                    newQuoteLineItem.Insurance_Rate__c = eachProd.insuranceAmount;
                    newQuoteLineItem.Insurance_Code__c = (assetProgramDetailsMap != null && assetProgramDetailsMap.containskey(eachProd.assetModelId)) 
                                                            ? assetProgramDetailsMap.get(eachProd.assetModelId).Insurance__r.Code__c : '';
                                     
                    newQuoteLineItem.Financed_Amount__c = eachProd.financeAmount;
                    newQuoteLineItem.Periodic_Amount__c = eachProd.periodicAmount;
                    newQuoteLineItemList.add(newQuoteLineItem);
                    count++;
                }
            }
        }
        
        for(ServicertoquoteCls eachServ : servicelist){
            if(String.isNotBlank(eachServ.product)){
                //for insert
                if(eachServ.operation == 'add'){
                    QuoteLineItem newQuoteLineItem = new QuoteLineItem();
                    newQuoteLineItem.Product2Id = eachServ.product;                
                    newQuoteLineItem.Quantity = String.isNotBlank(eachServ.Quantity)
                        ? integer.valueof(eachServ.Quantity) 
                        : 1;                  
                    newQuoteLineItem.QuoteId = existingQuote.id;                
                    newQuoteLineItem.UnitPrice = String.isNotBlank(eachServ.UnitPrice) 
                        ? integer.valueof(eachServ.UnitPrice)
                        : 1;                 
                    if(product2PeMap != null && product2PeMap.containskey(eachServ.product) && product2PeMap.get(eachServ.product).id != null)
                        newQuoteLineItem.PricebookEntryId  = product2PeMap.get(eachServ.product).Id;
                    
                    newQuoteLineItem.Maintenance_Amount__c = eachServ.maintAmount;
                    newQuoteLineItem.Periodic_Amount__c = eachServ.periodicAmount;
                    newQuoteLineItemList.add(newQuoteLineItem);
                }
            }
        }
    }

    /**
    *Name:updateQuoteLineItem
    *Purpose: Utility method to Update quote line items for a given quote
     */
    public static list<QuoteLineItem> updateQuoteLineItem(List<ProdtoquoteCls> prodlist,List<ServicertoquoteCls> servicelist, List<QuoteLineItem> updateQuoteLineList,Quote existingQuote, String offerOperation){
        
        map<id,ProdtoquoteCls> toUpdateLineidProdMap = new map<id,ProdtoquoteCls>();
        map<id,ServicertoquoteCls> toUpdateLineidServiceMap = new map<id,ServicertoquoteCls>();
        boolean isPrimaryFound = false;

        for(ProdtoquoteCls eachProd : prodlist){
            if(String.isNotblank(eachProd.product) && string.isNotBlank(eachProd.quotelineid)){
                //for update updateQuoteLineList
                if(eachProd.operation == 'update' || offerOperation == 'update'){
                    toUpdateLineidProdMap.put(eachProd.quotelineid,eachProd);  
                }
            }
        }
        for(ServicertoquoteCls eachServ : servicelist){
            if(String.isNotblank(eachServ.product) && string.isNotBlank(eachServ.quotelineid)){
                //for update
                if(eachServ.operation == 'update' || offerOperation == 'update'){
                    toUpdateLineidServiceMap.put(eachServ.quotelineid,eachServ);   
                }
            }
        }
        //if primary product is already checked, then set boolean to true
        for(QuoteLineItem updateQuoteLineItem : updateQuoteLineList){
            if(updateQuoteLineItem.Primary__c){
                isPrimaryFound = true;
                break;
            }
        }
        //looping over existing quote line list -products
        integer count = 1;
        for(QuoteLineItem updateQuoteLineItem : updateQuoteLineList){
            if(toUpdateLineidProdMap != NULL && toUpdateLineidProdMap.containskey(updateQuoteLineItem.id) && toUpdateLineidProdMap.get(updateQuoteLineItem.id) != NULL){               
                //updateQuoteLineItem.Product2Id = toUpdateLineidProdMap.get(updateQuoteLineItem.id).product;
                if(toUpdateLineidProdMap.get(updateQuoteLineItem.id).specification != NULL){
                    updateQuoteLineItem.Description = toUpdateLineidProdMap.get(updateQuoteLineItem.id).specification;
                }            
                updateQuoteLineItem.Quantity = toUpdateLineidProdMap.get(updateQuoteLineItem.id).Quantity != null 
                    ? integer.valueof(toUpdateLineidProdMap.get(updateQuoteLineItem.id).Quantity)
                    : 1;                      
                updateQuoteLineItem.UnitPrice = toUpdateLineidProdMap.get(updateQuoteLineItem.id).UnitPrice != null 
                    ? integer.valueof(toUpdateLineidProdMap.get(updateQuoteLineItem.id).UnitPrice) 
                    : 1;
                updateQuoteLineItem.Primary__c = (count == 1 && !isPrimaryFound) ? true : false;
                string itadProductName = (!prodIdToItadProdNameMap.isEmpty() && prodIdToItadProdNameMap.containskey(updateQuoteLineItem.Product2id)) 
                                            ? prodIdToItadProdNameMap.get(updateQuoteLineItem.Product2id) : 
                                            '';                 
                updateQuoteLineItem.ITAD_Fee__c = (itadProdNameToPriceMap.containskey(itadProductName.toLowerCase()) && itadProdNameToPriceMap.get(itadProductName.toLowerCase()) != null)
                                                    ? ((integer.valueof(updateQuoteLineItem.Quantity) * itadProdNameToPriceMap.get(itadProductName.toLowerCase())).round()) 
                                                    : 0;



                updateQuoteLineItem.Residual_Value_Rate__c = toUpdateLineidProdMap.get(updateQuoteLineItem.id).residualValue;
                                                        //toUpdateLineidProdMap.get(updateQuoteLineItem.id).residualValue != null? toUpdateLineidProdMap.get(updateQuoteLineItem.id).residualValue  : 0.0;
                
                updateQuoteLineItem.Insurance_Rate__c = toUpdateLineidProdMap.get(updateQuoteLineItem.id).insuranceAmount;                    
                                                        //toUpdateLineidProdMap.get(updateQuoteLineItem.id).insuranceAmount != null ? toUpdateLineidProdMap.get(updateQuoteLineItem.id).insuranceAmount : 0.0;
               
                updateQuoteLineItem.Financed_Amount__c = toUpdateLineidProdMap.get(updateQuoteLineItem.id).financeAmount != null 
                                                       ? toUpdateLineidProdMap.get(updateQuoteLineItem.id).financeAmount  
                                                       : 0.0;
                
                updateQuoteLineItem.Periodic_Amount__c = toUpdateLineidProdMap.get(updateQuoteLineItem.id).periodicAmount != null 
                                                       ? toUpdateLineidProdMap.get(updateQuoteLineItem.id).periodicAmount  
                                                       : 0.0;
                count++;
            } 
        }

         //looping over existing quote line list -services
        for(QuoteLineItem updateQuoteLineItem : updateQuoteLineList){
            if(toUpdateLineidServiceMap != NULL && toUpdateLineidServiceMap.containskey(updateQuoteLineItem.id) && toUpdateLineidServiceMap.get(updateQuoteLineItem.id) != NULL){
               // updateQuoteLineItem.Product2Id = toUpdateLineidServiceMap.get(updateQuoteLineItem.id).product;      
                updateQuoteLineItem.Quantity = toUpdateLineidServiceMap.get(updateQuoteLineItem.id).Quantity != null 
                    ? integer.valueof(toUpdateLineidServiceMap.get(updateQuoteLineItem.id).Quantity) 
                    : 1;        
                updateQuoteLineItem.UnitPrice = toUpdateLineidServiceMap.get(updateQuoteLineItem.id).UnitPrice != null 
                    ? integer.valueof(toUpdateLineidServiceMap.get(updateQuoteLineItem.id).UnitPrice)
                    : 1;       
                updateQuoteLineItem.Maintenance_Amount__c = toUpdateLineidServiceMap.get(updateQuoteLineItem.id).maintAmount != null 
                                                        ? toUpdateLineidServiceMap.get(updateQuoteLineItem.id).maintAmount   
                                                        : 0.0;
                updateQuoteLineItem.Periodic_Amount__c = toUpdateLineidServiceMap.get(updateQuoteLineItem.id).periodicAmount != null 
                                                        ? toUpdateLineidServiceMap.get(updateQuoteLineItem.id).periodicAmount   
                                                        : 0.0;
            }           
        }

        return updateQuoteLineList;
    }
    
   /**
    *Name:createOfferObj
    *Purpose: Utility method to form the offer object details.
    */
    public static OfferCls createOfferObj(list<Quote> quoteLst,list<contact> contList){
  
        //create the offer table
        OfferCls offer = new OfferCls();
        
        if(quoteLst != null && quoteLst.size() > 0){
            offer.rvType = quoteLst[0].Applicable_Offers__r.Offer__r.RV_Type__c;
            offer.offerid = quoteLst[0].Applicable_Offers__r.Offer__c;  
            offer.offerName = quoteLst[0].Applicable_Offers__r.Offer__r.Name;  
            offer.termsOption = quoteLst[0].Applicable_Offers__r.Offer__r.Selectable_Agreement_Term__c; 
            offer.termRange = quoteLst[0].Applicable_Offers__r.Offer__r.Include_Term_Range_Values__c;
            offer.defaultTerm = quoteLst[0].Term__c; 
            offer.freqOptions = quoteLst[0].Applicable_Offers__r.Offer__r.Selectable_Payment_Frequency__c;  
            offer.defaultFreq = quoteLst[0].Frequency__c;  
            offer.intOptions = quoteLst[0].Applicable_Offers__r.Offer__r.Selectable_Base_Rate__c == 'Both' ? Constants.str_Rate_Value : quoteLst[0].Applicable_Offers__r.Offer__r.Selectable_Base_Rate__c ; 
            offer.defaultInt = quoteLst[0].Interest__c;  
            offer.paymentTiming = quoteLst[0].Payment_Timing__c;
            offer.defaultcurncy = quoteLst[0].Applicable_Offers__r.Offer__r.CurrencyIsoCode;
            offer.programId = quoteLst[0].Applicable_Offers__r.Offer__r.Program__c;
            offer.applicableOfferId = quoteLst[0].Applicable_Offers__c;
            offer.itadLevel = quoteLst[0].ITAD_Category__c;
            offer.isItadApplicable = quoteLst[0].Applicable_Offers__r.Offer__r.Is_ITAD_Applicable__c;
        }else if(contList != NULL && contList.size() > 0){
            offer.rvType = contList[0].account.PartnerOffer__r.Offer__r.RV_Type__c;
            offer.offerid = contList[0].account.PartnerOffer__r.Offer__c;  
            offer.offerName = contList[0].account.PartnerOffer__r.Offer__r.Name;  
            offer.termsOption = contList[0].account.PartnerOffer__r.Offer__r.Selectable_Agreement_Term__c;
            offer.termRange = contList[0].account.PartnerOffer__r.Offer__r.Include_Term_Range_Values__c;
            offer.defaultTerm = contList[0].account.PartnerOffer__r.Offer__r.Default_Agreement_Term__c; 
            offer.freqOptions = contList[0].account.PartnerOffer__r.Offer__r.Selectable_Payment_Frequency__c; 
            offer.defaultFreq = contList[0].account.PartnerOffer__r.Offer__r.Default_Payment_Frequency__c;  
            offer.intOptions = contList[0].account.PartnerOffer__r.Offer__r.Selectable_Base_Rate__c  == 'Both' ? Constants.str_Rate_Value : contList[0].account.PartnerOffer__r.Offer__r.Selectable_Base_Rate__c ; 
            offer.defaultInt = contList[0].account.PartnerOffer__r.Offer__r.Default_Base_Rate__c;
            offer.defaultcurncy = contList[0].account.PartnerOffer__r.Offer__r.CurrencyIsoCode;
            offer.paymentTiming = contList[0].account.PartnerOffer__r.Offer__r.Default_Payment_Timing__c;
            offer.programId = contList[0].account.PartnerOffer__r.Offer__r.Program__c;
            offer.applicableOfferId = contList[0].account.PartnerOffer__c;
            offer.isItadApplicable = contList[0].account.PartnerOffer__r.Offer__r.Is_ITAD_Applicable__c;
        }
        
        return offer;
    }

    /**
    *Name: getQuoteDetailsOnChange
    *Purpose: To get the given quote details on change from the menu dropdown
    */
    @AuraEnabled
    public static TableWrapperCls getQuoteDetailsOnChange(string quoteId){
        
        string termStr = '';
        decimal financeVal = 0.0;
        decimal monthlyVal = 0.0;
        integer accumulatedService = 0;
        
        SubmitAppWrapperCls subAddWrCls;

        list<OfferCls> offerClsLst = new list<OfferCls>();
        list<ProductCls> prdClsLst = new list<ProductCls>();
        list<ServiceCls> srvClsLst = new list<ServiceCls>();
        list<ProdtoquoteCls> prodtoQuoteObjList = new list<ProdtoquoteCls>();
        List<ServicertoquoteCls> servicesInfoList = new List<ServicertoquoteCls>();
        list<QuoteLineItem> quoteLineItemLst;
        
        List<Quote> quoteLst = new WosSelector().queryQuoteDetails(quoteId);
      
        offerClsLst.add(createOfferObj(quoteLst, new list<contact>()));

        //find the related quote and quoteline items to the opportunity    
        quoteLineItemLst = new WosSelector().getQuoteLineDetails(quoteId);
        
        // map stores Product Id as a key and Asset Program Detail record as a value
        Map<Id,Asset_Program_Detail__c> offrPrdMap = new WoSSelector().getProductsFromProgram(offerClsLst[0].offerid, '');

        for(QuoteLineItem eachLine : quoteLineItemLst){
            if(eachLine.Product2.family == 'Maintenance'){
                ServiceCls srvCls = new ServiceCls();
                srvCls.serviceId = eachLine.Product2id;
                srvCls.serviceName = eachLine.Product2.name;
                srvCls.productType = eachLine.Product2.Family;
                srvCls.serviceDesc = eachLine.Product2.Description;
                srvCls.quantity = string.valueof(integer.valueof(eachLine.Quantity));
                srvCls.unitPrice = string.valueof(integer.valueof(eachLine.UnitPrice));
                srvCls.totalprice = string.valueof(integer.valueof(eachLine.TotalPrice));
                srvCls.operation = 'none';
                srvCls.quotelineid = eachLine.id;
                srvCls.isProductAvailable = offrPrdMap.get(eachLine.Product2id).Is_Active__c;
                monthlyVal += eachLine.TotalPrice;
                //accumulatedService += eachLine.Maintenance_Amount__c != null ? integer.valueof(eachLine.Maintenance_Amount__c) : 0;
                srvClsLst.add(srvCls);
                ServicertoquoteCls serviceInfo = new ServicertoquoteCls(
                    String.valueof(eachLine.Quantity),
                    String.valueof(eachLine.UnitPrice),
                    String.valueof(eachLine.TotalPrice),
                    eachLine.Product2.name
                );
                servicesInfoList.add(serviceInfo);
            }else if (eachLine.Product2.family != 'ITAD') {
                ProductCls prodcls = new ProductCls();
                prodcls.prodid = eachLine.Product2id;
                prodcls.prodName = eachLine.Product2.name;   
                prodcls.productType = eachLine.Product2.Family;            
                prodcls.prodDesc = String.isNotBlank(eachLine.Description) ? eachLine.Description : '';                                
                prodcls.quantity = string.valueof(integer.valueof(eachLine.Quantity));
                prodcls.unitPrice = string.valueof(integer.valueof(eachLine.UnitPrice));
                prodcls.totalprice = string.valueof(integer.valueof(eachLine.TotalPrice));
                prodcls.operation = 'none';
                prodcls.quotelineid = eachLine.id;
                prodcls.isProductAvailable = offrPrdMap.get(eachLine.Product2id).Is_Active__c;
                prodcls.insuranceRate = String.valueOf(eachLine.Insurance_Rate__c);
                prodcls.rvRate = String.valueOf(eachLine.Residual_Value_Rate__c);
                prodcls.isPurchaseOptionAvailable = eachLine.Residual_Value_Rate__c != null ? true : false ;
                prodcls.isInsuranceAvailable = eachLine.Insurance_Rate__c != null ? true : false;
                prdClsLst.add(prodcls);
                ProdtoquoteCls prodtoQuoteObj = new ProdtoquoteCls(
                    String.valueof(eachLine.Quantity),
                    String.valueof(eachLine.UnitPrice),
                    String.valueof(eachLine.TotalPrice),
                    eachLine.Product2.name,
                    eachLine.Description,
                    eachLine.Product2.Family,
                    String.valueOf(eachLine.Insurance_Rate__c),
                    String.valueOf(eachLine.Residual_Value_Rate__c)
                );
                prodtoQuoteObjList.add(prodtoQuoteObj);
            } 
        }

        TableWrapperCls tbr = new TableWrapperCls();
        tbr.offrcls = offerClsLst;
        tbr.prdCls = prdClsLst;
        tbr.srvCls = srvClsLst;
        tbr.opptyName = quoteLst[0].Opportunity.name;
        //passing the quote details
        tbr.quoteid = quoteLst[0].id;
        tbr.quoteStatus = quoteLst[0].Status;
        tbr.validTo = quoteLst[0].Valid_To__c;
        tbr.validFrom = quoteLst[0].Valid_From__c;
        tbr.latestQuote = quoteLst[0].Name;
        tbr.clonedQuoteName = quoteLst[0].Name;
        tbr.clonedQuoteNumber = quoteLst[0].QuoteNumber;
        tbr.totalFinanceVal = integer.valueof(quoteLst[0].Financed_Amount__c);
        tbr.rentalVal = integer.valueof(quoteLst[0].Rental_Amount__c);
        tbr.insuranceAmount = integer.valueof(quoteLst[0].Insurance_Amount__c);
        tbr.isDocumentQstnExist = new WosSelector().getDocumentQuestionares(quoteLst[0].Status,quoteLst[0].id);     
        tbr.accumulatedService = integer.valueof(quoteLst[0].Accumulated_Service__c);
        decimal baseRateVal = getBaseRateFromRate(string.valueof(quoteLst[0].Applicable_Offers__r.Offer__c),quoteLst[0].Term__c,quoteLst[0].Frequency__c.toLowerCase(),quoteLst[0].Applicable_Offers__r.Offer__r.Default_Base_Rate__c);
        tbr.baseRate = string.valueof(baseRateVal); 
        tbr.futureValue = (quoteLst[0].Future_Value__c != null) ? quoteLst[0].Future_Value__c : null;
        tbr.downpayment = (quoteLst[0].Downpayment__c != null) ? Decimal.valueOf(quoteLst[0].Downpayment__c) : null;
        tbr.viewRentPerMonth = quoteLst[0].Rent_Per_Month__c;
        tbr.disabledCalculationParams = quoteLst[0].Disabled_Calculation_Params__c;
        //for submit application request details
        if(quoteLst != null && quoteLst.size() > 0){
            subAddWrCls = new SubmitAppWrapperCls(
                quoteLst[0].Opportunity.Owner.Name,
                quoteLst[0].Applicable_Offers__r.Offer__r.Program__r.Business_Unit__r.Name,
                string.valueof(quoteLst[0].Opportunity.CreatedDate),
                quoteLst[0].Applicable_Offers__r.name,
                quoteLst[0].Applicable_Offers__r.Offer__r.name,
                quoteLst[0].Opportunity.CurrencyIsoCode,
                quoteLst[0].Term__c,
                quoteLst[0].Frequency__c,
                quoteLst[0].Payment_Timing__c,
                //string.valueof(quoteLst[0].Opportunity.Amount),
                string.valueof(quoteLst[0].Financed_Amount__c),
                string.valueof(quoteLst[0].Nominal_Interest_Rate__c),
                prodtoQuoteObjList,
                servicesInfoList,
                ''
            );
        }        
        tbr.submitAddWrapper = subAddWrCls;
        tbr.appliedPR = quoteLst[0].Applied_Purchase_Option__c;
        tbr.accountRegionCode = quoteLst[0].Opportunity.account.Account_Region_Code__c;
        return tbr;
    }

    /*
    *Method name:doCopyQuoteDetails
    *Purpose: to copy the exsiting quote details and create a new duplicate one
    */
    @AuraEnabled
    public static TableWrapperCls doCopyQuoteDetails(string copiedQuoteId, id behaveOnUserId){

        list<QuoteLineItem> newQliList = new list<QuoteLineItem>();
        TableWrapperCls twr = new TableWrapperCls();
        Quote copiedQuoteDetails;
        List<Quote> relatedQuotes;
        List<Asset_Program_Detail__c> assetProgramDetails;

        try{
            if(String.isNotBlank(copiedQuoteId)){
                copiedQuoteDetails = new WosSelector().getCopiedQuote(copiedQuoteId);
                //get all the quotes for this opportunity
                relatedQuotes = new WosSelector().getRelatedQuotes(copiedQuoteDetails);
                assetProgramDetails = new WosSelector().getAssetProgramDetails(copiedQuoteDetails);
            }
        }catch(Exception e){
            ErrorLogger errorLog = new ErrorLogger();
            errorLog.logException(e, Constants.GENERIC_ERRORLOG_RECORDTYPE, copiedQuoteId, true); 
            throw new ErrorLogger.ErrorLoggerException( 'Some error happened while getting records', e);            
        }

        Set<Id> avaliableProducts = new Set<Id>();
        List<QuoteLineItem> copiedQuoteLineItems = new List<QuoteLineItem>();
        String infoMessage;

        for (Asset_Program_Detail__c assetProgramDetail : assetProgramDetails) {
            if (assetProgramDetail.Is_Active__c) {
                avaliableProducts.add(assetProgramDetail.Product__c);
            }
        }

        for (QuoteLineItem quotelineItem : copiedQuoteDetails.QuoteLineItems) {
            if (avaliableProducts.contains(quotelineItem.Product2id)) {
                copiedQuoteLineItems.add(quotelineItem);
            } else {
                infoMessage = System.Label.Products_Do_Not_Longer_Exist;
            }
        }
    
        Quote newQuoteClone = copiedQuoteDetails.clone(false, false, false, false); //cloning the quote record
        newQuoteClone.Status = Constants.QUOTE_CALCULATION_STATUS;
        newQuoteClone.Auto_Decision__c = '';
        newQuoteClone.Valid_From__c = null;
        newQuoteClone.Valid_To__c = null;
        newQuoteClone.Decision_Maker__c = '';
        newQuoteClone.Name = 'Version-' + getLatestQuoteVersion(relatedQuotes);
        newQuoteClone.OwnerId = behaveOnUserId;
        try{
            if(newQuoteClone != null){            
                new GenericUtilityClass.WoSDMLProcessor().insertRecords(new list<Quote>{newQuoteClone}); 
            }
        }catch(Exception e){
            ErrorLogger errorLog = new ErrorLogger();
            errorLog.logException(e, Constants.GENERIC_ERRORLOG_RECORDTYPE, '', true); 
        }

        //looping over the quote line items of the current quote
        //for(QuoteLineItem qli : copiedQuoteDetails.QuoteLineItems){   
        for(QuoteLineItem qli : copiedQuoteLineItems){      
            QuoteLineItem newQliClone = qli.clone(false, false, false, false);
            newQliClone.Quoteid = newQuoteClone.id;
            newQliList.add(newQliClone);
        }
        try{
            if(newQliList.size() > 0){
              
                new GenericUtilityClass.WoSDMLProcessor().insertRecords(newQliList); 
            }            
        }catch(Exception e){
            ErrorLogger errorLog = new ErrorLogger();
            errorLog.logException(e, Constants.GENERIC_ERRORLOG_RECORDTYPE, newQuoteClone.id, true); 
        }
        //calling the method to pass the quote details to lwc
        twr = getQuoteDetailsOnChange(newQuoteClone.id); 
        
        if (infoMessage != null) {
            twr.infoMessage = infoMessage;
        }

        return twr;
    }

    /**
    *Name: getMyOpportunties
    *Purpose: To get the opportunities details for the loggedin user
    */
    @AuraEnabled(cacheable=true)
    public static TableWrapperCls getMyOpportunties(string ownerId,string searchStr){
        
        List<Opportunity> myOppList;
        //String myOppListViewId = '';
        try{
           //SOQL to get my opportunities order by last modified date. only get the opptys where a synced quote exist
            //myOppList = new WosSelector().getMyOppList();
            myOppList = getMyOppList(searchStr);
        }catch(Exception e){
            ErrorLogger errorLog = new ErrorLogger();
            errorLog.logException(e, Constants.GENERIC_ERRORLOG_RECORDTYPE, ownerId, true); 
            throw new ErrorLogger.ErrorLoggerException('Some error happened while getting Opportunities.', e);         
        }
       
        list<OpportunityCls> newOppClsList = new list<OpportunityCls>();
        if(myOppList != null && myOppList.size() > 0){
            for(Opportunity eachOpp : myOppList){
                OpportunityCls oppCls = new OpportunityCls();
                oppCls.opptyName = eachOpp.Opportunity_Name__c;
                oppCls.opptyId = eachOpp.id;
                oppCls.customer = eachOpp.End_User__r.name ; 
                oppCls.rent = eachOpp.SyncedQuote.Rental_Amount__c != null ? Math.round(eachOpp.SyncedQuote.Rental_Amount__c).format() : '0';        
                //integer financeAmountRound = Math.round(eachOpp.SyncedQuote.Financed_Amount__c);
                oppCls.financedAmount = eachOpp.SyncedQuote.Financed_Amount__c != null ? Math.round(eachOpp.SyncedQuote.Financed_Amount__c).format() : '0';//Math.round(eachOpp.Amount.format());
                oppCls.status = eachOpp.SyncedQuote.Status;
                oppCls.term = eachOpp.SyncedQuote.Term__c;
                oppCls.lastmodifieddate = String.valueof(eachOpp.SyncedQuote.LastModifiedDate.date());              
                oppCls.creditExpDate = string.valueof(eachOpp.SyncedQuote.Valid_To__c );

                newOppClsList.add(oppCls);
            }
        }
        TableWrapperCls tbr = new TableWrapperCls();
        tbr.oppClsList = newOppClsList;
        
        return tbr;
    }
    /**
    *Name: createOpportunity
    *Purpose: To Create the Oppotunity
    */
    @AuraEnabled
    public static string createOpportunity(decimal amount,string acctid, string currencyCode, id behaveOnUserId){

        Opportunity newopp = new Opportunity();
        newopp.amount = amount;
        newopp.StageName = Constants.OPPTY_DEFAULT_STAGE;
        newOpp.Type = Constants.NEW_STATUS;
        newOpp.recordtypeid = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(Constants.RETAIL_OPPORTUNITY_RECORDTYPE_DEVELOPER_NAME).getRecordTypeId();
        newOpp.Accountid = acctid;
        newOpp.Closedate = system.today()+365;
        newOpp.CurrencyIsoCode = currencyCode;
        newOpp.OwnerId = behaveOnUserId !=null  ? behaveOnUserId : UserInfo.getUserId();

        try{
            //insert newopp;   
            new GenericUtilityClass.WoSDMLProcessor().insertRecords(new list<Opportunity>{newopp});       
        }catch(Exception e){
            ErrorLogger errorLog = new ErrorLogger();
            errorLog.logException(e, Constants.GENERIC_ERRORLOG_RECORDTYPE, acctid, true);           
        }
        return newopp.id;

    }

    /**
    *Name: getRateDetail
    *Purpose: to find the base rate from rate line item
     */
    @AuraEnabled(cacheable=true)
    public static String getRateDetails(String offerId, String term, String frequency, String interest){
        frequency = frequency.toLowerCase();
        string fixedBaseRateId = '';
        string variableBaseRateId = '';
        decimal baseRate = 0.0;
        List<Rate_Line_Item__c> rateLineItemList;

        list<offer__c> offerList = new WosSelector().getOfferRecordDetails(offerId); //qeury the offer record
        string termValue = getNextHighestTerm(offerList[0].Selectable_Agreement_Term__c,term);
        
        if(interest == Constants.FIXED_RATE_TYPE){
            fixedBaseRateId = offerList[0].Base_Rate_Fixed__c;
        }else if(interest == Constants.VARIABLE_RATE_TYPE){
            variableBaseRateId = offerList[0].Base_Rate_Variable__c;
        } 
        string rateLineItemQuery = 'SELECT id,Term__c,Rate_Value__c,Term__r.Term_Value__c FROM Rate_Line_Item__c ';
        if(String.isNotBlank(fixedBaseRateId)){
            rateLineItemQuery += ' WHERE Rate__c =\''+ String.escapeSingleQuotes(fixedBaseRateId)+'\'';
        }else if(String.isNotBlank(variableBaseRateId)){
            rateLineItemQuery += ' WHERE Rate__c = \''+ String.escapeSingleQuotes(variableBaseRateId)+'\'';
        }
        
        try{
            rateLineItemList = (List<Rate_Line_Item__c>)new WosSelector().getRecordsList(rateLineItemQuery);
        }catch(Exception e){
            ErrorLogger errorLog = new ErrorLogger();
            errorLog.logException(e, Constants.GENERIC_ERRORLOG_RECORDTYPE, offerId, true); 
            throw new ErrorLogger.ErrorLoggerException('Some error happened while Quering Base rate.', e);   
        }
           
        map<string,integer> paymentFrqncyMap = new map<string,integer>{'monthly'=>30,'quarterly'=>90,'semi-annually'=>180,'annually'=>360}; 
        
        if(rateLineItemList != null && rateLineItemList.size() > 0){
            for(Rate_Line_Item__c eachRateLine : rateLineItemList){
                //for fixed interest rate
                if(interest == Constants.FIXED_RATE_TYPE && termValue == string.valueof(eachRateLine.Term__r.Term_Value__c)){
                    baseRate = eachRateLine.Rate_Value__c;
                }else if(interest == Constants.VARIABLE_RATE_TYPE && paymentFrqncyMap.containsKey(frequency) && paymentFrqncyMap.get(frequency) == eachRateLine.Term__r.Term_Value__c ){
                    //for variable interest rate
                    baseRate = eachRateLine.Rate_Value__c;
                }
            }
        }

        RateDetails rateDetails = new RateDetails();
        rateDetails.rateName = String.isNotBlank(fixedBaseRateId)
            ? offerList[0].Base_Rate_Fixed__r.Name
            : offerList[0].Base_Rate_Variable__r.Name;

        rateDetails.rateValue = baseRate; 
        rateDetails.costOfFunds = String.isNotBlank(fixedBaseRateId)
            ? offerList[0].Base_Rate_Fixed__r.Cost_Of_Funds__c
            : offerList[0].Base_Rate_Variable__r.Cost_Of_Funds__c;    

        return JSON.serialize(rateDetails);
    }

    /**
    *Name:  getMarginMatrixValue
    *Purpose: to find margin matrix value by user id, term and financed amount
    */
    @AuraEnabled(cacheable=true)
    public static Decimal getMarginMatrixValue(Id behaveOnUserId, Integer selectedTermValue, Decimal selectedAmount){
        Id marginMatrixId = GenericUtilityClass.getUserInfo(behaveOnUserId).Contact.Account.Margin_Matrix__c;
        return SubmitApplicationHelper.getMarginMatrixValue(marginMatrixId, selectedTermValue, selectedAmount);
    }

    /**
    *Name: getRVandInsuranceValues
    *Purpose: to find RV and Insurance values by offer and products Ids
    */
    @AuraEnabled(cacheable=true)
    public static String getRVandInsuranceValues(Id offerId, List<Id> productIDs, Integer term) {
      
        Map<Id, List<RV_Matrix_Line_Item__c>> RVMatrixLineItems = new Map<Id, List<RV_Matrix_Line_Item__c>>();
       
        Applicable_Offer__c applicableOffer = new WoSSelector().getApplicableOffer(offerId);
        Id assetProgramId = applicableOffer.Offer__r.Program__r.Asset_Program__c;
        Id partnerId = applicableOffer.Account__c;
        String rvType = applicableOffer.Offer__r.RV_Type__c;
           

        // get list of Asset_Program_Detail__c (contains info about products, RV categories and priorities (RV Matrix lookup). 
        List<Asset_Program_Detail__c> assetProgramDetails = new WoSSelector().getAssetProgramDetails(assetProgramId, productIDs);

        if (assetProgramDetails.isEmpty()) {
            return '';
        }

        // get list of junctions between Offer and RV Matrix. it is used to check Asset Program Detail priority 
        List<Applicable_RV__c> applicableRVs = rvType == Constants.DLL_3RDPARTY_RV
                                               ? new AssetModelWebService.WoSSelector().getApplicableRVs(offerId) 
                                               : new List<Applicable_RV__c>();

        Map<Id,String> RVMatrixNameByIds = new Map<Id,String>();

        for (Applicable_RV__c applicableRVItem : applicableRVs) {
            RVMatrixNameByIds.put(applicableRVItem.RV_Matrix__c, applicableRVItem.RV_Matrix__r.Name);
        }

        // get list of wrapper class witch contains info about Asset Program Detail (stores product info) 
        // with appropriate to the Offer RV Matrix and Category or Purchase option values
        List<AssetModelWebService.AssetModelItemWrapper> assetModelWrappers = AssetModelWebService.getAssetProgramDetailsWrappers(assetProgramDetails, RVMatrixNameByIds.keySet(), partnerId,rvType);

        // get map of RV_Matrix_Line_Item__c with Category, RV value, Duration by RV Matrix Id
        if (rvType == Constants.DLL_3RDPARTY_RV ){
            RVMatrixLineItems  = AssetModelWebService.getRVMatrixLineItems(RVMatrixNameByIds.keySet());
        }
       
        List<RVandInsuranceDetails> rvAndInsuranceDetails = new List<RVandInsuranceDetails>();

        for (AssetModelWebService.AssetModelItemWrapper assetProgramWrapper : assetModelWrappers) {
            String assetProgramDetailId = assetProgramWrapper.assetProgramDetail.Id;
            String productId = assetProgramWrapper.assetProgramDetail.Product__c;
            String productName = assetProgramWrapper.assetProgramDetail.Product__r.Name;
            
            String RVMatrixId = assetProgramWrapper.RVMatrixId;            
            String categoryName = assetProgramWrapper.categoryName;
            
            Double defaultRV = assetProgramWrapper.defaultRV;
            Double minRV = assetProgramWrapper.minRV;
            Double maxRV = assetProgramWrapper.maxRV;
            
            String insuranceId = assetProgramWrapper.insuranceInfo?.Id;

            RVandInsuranceDetails details = new RVandInsuranceDetails();
            details.productId = productId;
            details.productName = productName;
            
             RVDetails rvDetails = new RVDetails();

            if (rvType == Constants.DLL_3RDPARTY_RV && categoryName != null) {
              
                rvDetails.category = categoryName;
                //rvDetails.value = residualValue;
                rvDetails.rvMatrixName = RVMatrixNameByIds.get(RVMatrixId);
                
                details.residualValue = rvDetails;
            } else if(rvType == Constants.PURCHASE_OPTION_RV){                
               // rvDetails.value = defaultRV;
                rvDetails.minRV = minRV;
                rvDetails.maxRv = maxRV;
                
                details.residualValue = rvDetails;
            }

            if (insuranceId != null) {
                               
                Double cost =  assetProgramWrapper.insuranceInfo.Cost__c != null ? assetProgramWrapper.insuranceInfo.Cost__c : 0;
                Double minMargin =  assetProgramWrapper.insuranceInfo.Minimum_Margin__c != null ? assetProgramWrapper.insuranceInfo.Minimum_Margin__c : 0;
                Double maxMargin =  assetProgramWrapper.insuranceInfo.Maximum_Margin__c != null ? assetProgramWrapper.insuranceInfo.Maximum_Margin__c : 0;
                
                InsuranseDetails insuranseDetails = new InsuranseDetails();
                insuranseDetails.code = assetProgramWrapper.insuranceInfo.Name;
               // insuranseDetails.value = insuranceValue;
                insuranseDetails.minMargin = cost + minMargin;
                insuranseDetails.maxMargin = cost + maxMargin;

                details.insurance = insuranseDetails;
            }

            rvAndInsuranceDetails.add(details);
        }

        return JSON.serialize(rvAndInsuranceDetails); 
    }

    //SOQL to get the opportunity records for the logged in user. no need of owner id in WHERE clause because OWD of oppty object is PRIVATE
    private static list<Opportunity> getMyOppList(string searchStr){
        
        String opptyQueryStr = 'SELECT id,name,Opportunity_Name__c,Amount,Account.name,SyncedQuote.Status,';  
        opptyQueryStr += 'SyncedQuote.Term__c,SyncedQuote.LastModifiedDate, SyncedQuote.Rental_Amount__c,';
        opptyQueryStr += 'CurrencyIsoCode,End_User__c,End_User__r.name,SyncedQuote.Financed_Amount__c,SyncedQuote.Valid_To__c FROM Opportunity '; 
        opptyQueryStr += ' WHERE SyncedQuote.id != NULL AND recordtype.developername = ' + '\''+String.escapeSingleQuotes(Constants.RETAIL_OPPORTUNITY_RECORDTYPE_DEVELOPER_NAME) +'\'';
        opptyQueryStr += ' AND SyncedQuote.Status != \'Cancelled\' ';
        if(String.isNotBlank(searchStr)){
            opptyQueryStr += ' AND (End_User__r.name LIKE '+'\''+String.escapeSingleQuotes(searchStr) +'%\'';
            opptyQueryStr += ' OR Account.name LIKE '+'\''+String.escapeSingleQuotes(searchStr) +'%\'';
            opptyQueryStr += ' OR Name LIKE '+'\'%'+String.escapeSingleQuotes(searchStr) +'%\')';
        }
        opptyQueryStr += ' ORDER BY SyncedQuote.LastModifiedDate DESC LIMIT 50 ';
        
        return Database.Query(opptyQueryStr);
    }

    // inner class-selector
    public without sharing class WoSSelector {

        private List<Sobject> getRecordsList(String finalQuery) {
           
            return database.query(finalQuery);
        }
        
        /**
        *Method Name: getApplicableOffers
        * Purpose: to get the applicable offers for a partner
        */
        private List<Applicable_Offer__c> getApplicableOffers(Id behaveOnUserId) {
            User usr = [SELECT Id, Name, ContactId, Contact.AccountId FROM User WHERE Id =: behaveOnUserId];
            return [
                    SELECT Id, Name, Offer__c, Offer__r.Name 
                    FROM Applicable_Offer__c 
                    WHERE Account__c =: usr.Contact.AccountId
                ];
        }
        
        @TestVisible
        private map<string,Asset_Program_Detail__c> getAssetProgramLineRecords(set<id> assetDetailsIds){
            return new map<string,Asset_Program_Detail__c>([SELECT id,Insurance__r.Code__c                                                                  
                                                                FROM Asset_Program_Detail__c WHERE 
                                                                id in: assetDetailsIds]);

        }

        /**
        *Method Name: getProductsFromProgram
        * Purpose: to get the related Product details of the offer from the offer product object. match with the currency of the offer
        */
        @TestVisible
        private map<id,Asset_Program_Detail__c> getProductsFromProgram(string offerId, string searchTerm){
            // map stores Product Id as a key and Asset Program Detail record as a value
            Map<Id,Asset_Program_Detail__c> product2IdtoItadMap = new Map<Id,Asset_Program_Detail__c>();
            try{
                if(offerId != null){
                    Offer__c offerRecord = [SELECT Program__r.Asset_Program__c FROM Offer__c WHERE id =: offerId LIMIT 1];
                    string assetProgId = offerRecord.Program__r.Asset_Program__c;

                    list<Asset_Program_Detail__c> assetProgDetails = [SELECT Product__r.Family,Product__c,Product__r.name,
                                                                       Is_Active__c ,ITAD_Product__c,ITAD_Product__r.name,
                                                                      Default_Purchase_Option__c,Max_Purchase_Option__c,Min_Purchase_Option__c,
                                                                      Insurance__c
                                                                        FROM Asset_Program_Detail__c WHERE
                                                                        Product__r.Name Like: '%' + String.escapeSingleQuotes(searchTerm.trim()) + '%' AND 
                                                                        Asset_Program__c =: assetProgId LIMIT 40];
                    
                    for(Asset_Program_Detail__c eachAsset : assetProgDetails){
                        product2IdtoItadMap.put(eachAsset.Product__c, eachAsset);           
                    }
                }
                
            }catch(Exception e) {
                ErrorLogger errorLog = new ErrorLogger();
                errorLog.logException(e, Constants.GENERIC_ERRORLOG_RECORDTYPE, offerId, true); 
            }   
            return product2IdtoItadMap;      
        }
        
        /**
        *Name: getContactOfferDetails
        *Purpose: Utility method to get the contact details for the logged in user. Also get the account, offer details for the logged in user
        */
        private list<Contact> getContactOfferDetails(Id behaveOnUserId){
            List<Contact> conList = new List<Contact>();
            try{
                //get the contact id of the current user
                User usr = [SELECT ContactId,View_Rent_per_Month__c FROM User WHERE Id=:behaveOnUserId];
                User currentusr = [SELECT View_Rent_per_Month__c FROM User WHERE Id=:UserInfo.getUserId()];
                viewRentPerMonth = currentusr.View_Rent_per_Month__c;
                
                conList = [SELECT id, name,Email, account.PartnerOffer__c,accountid, 
                                        account.PartnerOffer__r.Offer__c,
                                        account.PartnerOffer__r.Offer__r.Name,
                                        account.PartnerOffer__r.Offer__r.RV_Type__c,
                                        account.PartnerOffer__r.Offer__r.Selectable_Payment_Frequency__c,
                                        account.PartnerOffer__r.Offer__r.Default_Payment_Frequency__c,
                                        account.PartnerOffer__r.Offer__r.Default_Agreement_Term__c,
                                        account.PartnerOffer__r.Offer__r.Selectable_Agreement_Term__c,
                                        account.PartnerOffer__r.Offer__r.Default_Base_Margin__c,
                                        account.PartnerOffer__r.Offer__r.Selectable_Base_Margin__c,
                                        account.PartnerOffer__r.Offer__r.Selectable_Base_Rate__c,
                                        account.PartnerOffer__r.Offer__r.Default_Base_Rate__c,
                                        account.PartnerOffer__r.Offer__r.Base_Rate_Fixed__c,
                                        account.PartnerOffer__r.Offer__r.Base_Rate_Variable__c,
                                        account.PartnerOffer__r.Offer__r.CurrencyIsoCode ,
                                        account.PartnerOffer__r.Offer__r.Include_Term_Range_Values__c,
                                        account.PartnerOffer__r.Offer__r.Default_Payment_Timing__c,
                                        account.PartnerOffer__r.Offer__r.Selectable_Payment_Timing__c,
                                        account.PartnerOffer__r.Offer__r.Program__c,
                                        account.PartnerOffer__r.Offer__r.Is_ITAD_Applicable__c,
                                        account.PartnerOffer__r.Offer__r.Selectable_Quick_Calculation_Term__c,
                                        account.Account_Region_Code__c
                                        FROM Contact WHERE id=: usr.contactId ];
            }catch(Exception e){
                ErrorLogger errorLog = new ErrorLogger();
                errorLog.logException(e, Constants.GENERIC_ERRORLOG_RECORDTYPE, '', true);         
            }      
            return conList;
        }
        
        private List<Opportunity> getOpportunities(string oppIdFromUrl){
            return [SELECT id, name,owner.name,CreatedDate,CurrencyIsoCode,Amount 
                            FROM Opportunity WHERE id =: oppIdFromUrl];
        
        }
        
        private List<Quote> getQuotes(list<opportunity> oppLst){
            
            return [SELECT id,QuoteNumber,Name,Frequency__c,Interest__c,Term__c ,Applied_Purchase_Option__c,
                                Applicable_Offers__c,Applicable_Offers__r.Offer__c,Nominal_Interest_Rate__c,
                                Applicable_Offers__r.Offer__r.Program__c,Applicable_Offers__r.name,
                                Applicable_Offers__r.Offer__r.name,OpportunityId,IsSyncing, 
                                Applicable_Offers__r.Offer__r.Selectable_Agreement_Term__c, 
                                Applicable_Offers__r.Offer__r.Selectable_Payment_Frequency__c, 
                                Applicable_Offers__r.Offer__r.Selectable_Base_Rate__c, 
                                Applicable_Offers__r.Offer__r.Include_Term_Range_Values__c,
                                Applicable_Offers__r.Offer__r.Default_Base_Rate__c,
                                Applicable_Offers__r.Offer__r.CurrencyIsoCode,
                                Applicable_Offers__r.Offer__r.RV_Type__c,
                                Status,
                                Rental_Amount__c,Financed_Amount__c ,ITAD_Category__c,Insurance_Amount__c,
                                Accumulated_Service__c,
                                Payment_Timing__c, Applicable_Offers__r.Offer__r.Program__r.Business_Unit__r.Name ,
                                Applicable_Offers__r.Offer__r.Is_ITAD_Applicable__c, Valid_To__c, Valid_From__c,
                                Downpayment__c, Future_Value__c, Disabled_Calculation_Params__c 
                                FROM Quote WHERE Opportunityid =:oppLst[0].id 
                                ORDER BY QuoteNumber DESC];
        }
        
        /**
        *Name:getQuoteLineDetails
        *Purpose: Utility method to SOQL on the quote line items for a given quote
        */
        public list<QuoteLineItem> getQuoteLineDetails(string quoteId){
            return [SELECT id,Quote.QuoteNumber,LineNumber,Quoteid,
                                    Product2id,Product2.name,Product2.Description, Quote.Opportunity.name,Quote.Opportunity.Account.name,
                                    Quote.Opportunityid,Quote.Name,Quote.Opportunity.Owner.Name,Quote.Opportunity.CreatedDate,
                                    Product2.family, Primary__c,Quote.Term__c,Quote.Financed_Amount__c,Quote.Frequency__c, Quote.Interest__c,
                                    Quote.Payment_Timing__c,Quote.Applicable_Offers__r.Offer__r.Program__c, Quote.Applicable_Offers__c,
                                    UnitPrice,Quantity,TotalPrice,Description,Quote.Applicable_Offers__r.name,
                                    Quote.Applicable_Offers__r.Offer__r.Program__r.Business_Unit__r.Name ,
                                    Quote.Applicable_Offers__r.Offer__r.Program__r.Asset_Program__c, Quote.ITAD_Category__c,
                                    Quote.Applicable_Offers__r.Offer__r.name,Quote.CurrencyIsoCode,Quote.Nominal_Interest_Rate__c,
                                    Quote.Opportunity.End_User__r.External_Identifier__c,Quote.Opportunity.End_User__c,
                                    Quote.Opportunity.End_User__r.Name,quote.Value_downpayment__c,quote.Value_term__c,
                                    Quote.Opportunity.End_User__r.BillingStreet,Quote.Opportunity.owner.email,
                                    Quote.Opportunity.End_User__r.BillingCity,
                                    Quote.Opportunity.End_User__r.BillingPostalCode,
                                    Quote.Applied_Purchase_Option__c,
                                    Quote.Applicable_Offers__r.Offer__r.RV_Type__c,
                                    Insurance_Rate__c, Residual_Value_Rate__c,
                                    Maintenance_Amount__c 
                                    FROM QuoteLineItem 
                                    WHERE QuoteId =: quoteId];                                           
        }
        
        /**
        *Name: getDocumentQuestionares
        *Purpose: utility method to do SOQL on Document_Questionnaire__c object
        */
        private boolean getDocumentQuestionares(string quoteStatus, string quoteId){
        
            //if(String.isNotBlank(quoteStatus) &&  String.isNotBlank(quoteId) && (quoteStatus == Constants.QUOTE_DOCUMENT_GEN_STATUS || quoteStatus == Constants.QUOTE_PENDINGESIGN_STATUS || quoteStatus == Constants.QUOTE_REVIEWCOMPLETED_STATUS)){
            if(String.isNotBlank(quoteId)){
                list<Document_Questionnaire__c> documentQstnsList = [SELECT id FROM Document_Questionnaire__c where Quote__c =: quoteId];
                return documentQstnsList.size() > 0 ? true : false;
            }
            return false;        
        }
        
        /**
        *Name: getOfferRecordDetails
        *Purpose: utility method to soql on offer object
        *param:offer id
        */
        private List<Offer__c> getOfferRecordDetails(string offeridstr){ 
            
            return [SELECT id, name, Selectable_Payment_Frequency__c,
                        Default_Payment_Frequency__c,
                        Default_Agreement_Term__c,
                        Selectable_Agreement_Term__c,
                        Selectable_Base_Rate__c,
                        Default_Base_Rate__c,
                        Default_Payment_Timing__c,
                        Base_Rate_Fixed__c,
                        Base_Rate_Fixed__r.Name,
                        Base_Rate_Fixed__r.Cost_Of_Funds__c,
                        Base_Rate_Variable__c,
                        Base_Rate_Variable__r.Name,
                        Base_Rate_Variable__r.Cost_Of_Funds__c,
                        Program__c, Is_ITAD_Applicable__c, 
                        Include_Term_Range_Values__c,
                        CurrencyIsoCode, //IS_RV_Applicable__c,
                        RV_Type__c,
                        Program__r.Asset_Program__c
                        FROM offer__c WHERE id =: offeridstr 
                    ];
        }
        
        private Applicable_Offer__c getApplicableOfferByAccount(list<contact> contList,string offeridstr){
            return [SELECT id from Applicable_Offer__c where Account__c =: contList[0].accountId 
                    and Offer__c=: offeridstr limit 1];     
        }
        
        /**
        *Name:queryQuoteDetails
        *Purpose: Utility method to Query the given quote
        */
        public List<Quote> queryQuoteDetails(string quoteId){
            
            return [SELECT id,QuoteNumber,Name,Frequency__c,Interest__c,Term__c ,Applied_Purchase_Option__c,
                                        Quote.Opportunity.name, IsSyncing, OpportunityId,
                                        Applicable_Offers__c,Applicable_Offers__r.Offer__c,
                                        Applicable_Offers__r.Offer__r.name,CurrencyIsoCode, 
                                        Applicable_Offers__r.Offer__r.Selectable_Agreement_Term__c, 
                                        Applicable_Offers__r.Offer__r.Selectable_Payment_Frequency__c, 
                                        Applicable_Offers__r.Offer__r.Selectable_Base_Margin__c, 
                                        Applicable_Offers__r.Offer__r.Selectable_Base_Rate__c, 
                                        Applicable_Offers__r.Offer__r.Default_Base_Rate__c,
                                        Applicable_Offers__r.Offer__r.Include_Term_Range_Values__c,
                                        Applicable_Offers__r.Offer__r.CurrencyIsoCode,
                                        Applicable_Offers__r.Offer__r.RV_Type__c,
                                        Status,
                                        Opportunity.Owner.Name,
                                        Applicable_Offers__r.Offer__r.Program__r.Business_Unit__r.Name,
                                        Opportunity.CreatedDate,
                                        Applicable_Offers__r.name,
                                        Opportunity.CurrencyIsoCode,
                                        Rental_Amount__c,Financed_Amount__c,Nominal_Interest_Rate__c,
                                        Applicable_Offers__r.Offer__r.Default_Payment_Timing__c,
                                        Opportunity.Amount,Insurance_Amount__c,Accumulated_Service__c,
                                        Payment_Timing__c ,ITAD_Category__c,
                                        Applicable_Offers__r.Offer__r.Is_ITAD_Applicable__c,
                                        Valid_From__c, Valid_To__c,
                                        Downpayment__c, Future_Value__c ,Rent_Per_Month__c,
                                        Disabled_Calculation_Params__c,
										Opportunity.account.Account_Region_Code__c                    
                                        FROM Quote where id=: quoteId]; 
        }
        
        /**
        *Name: getApplicableOffer
        *Purpose: utility method to do SOQL on applicable offer object
        */
        private Applicable_Offer__c getApplicableOffer(string offerid){
            
           return [SELECT id,name,Account__c,offer__c ,Offer__r.Program__r.Business_Unit__r.Name,Offer__r.Name,
                                    Offer__r.Base_Rate_Fixed__c,Offer__r.Base_Rate_Variable__c,
                                    Offer__r.Program__r.Asset_Program__c, Offer__r.RV_Type__c
                                    FROM Applicable_Offer__c 
                                    WHERE offer__c =: offerid limit 1];
        }
        
        private list<Opportunity> getOppAndQuoteList(string opptyId){
            
            return [SELECT id, Amount,Owner.Name,CreatedDate,
                                                Name,account.PartnerOffer__c, CurrencyIsoCode,Pricebook2.Id, 
                                                (SELECT QuoteNumber,Name FROM Quotes ORDER BY QuoteNumber DESC) 
                                                FROM Opportunity WHERE  id=: opptyId];
        }
        
        private Quote getQuoteById(quote newQuote){
            
            return [SELECT Name,QuoteNumber FROM Quote WHERE id=: newQuote.id LIMIT 1];
        }
        
        private list<PricebookEntry> getPbeList(set<id> product2idSet,Quote existingQuote){
            
            return [SELECT Id,Product2Id FROM PricebookEntry WHERE Product2Id in: product2idset and CurrencyIsoCode =: existingQuote.CurrencyIsoCode];
        }
        
        /**
        *Name:getAssetProgramDetails
        *Purpose: Utility method to SOQL on asset program detail object
        */
        public list<Asset_Program_Detail__c> getAssetProgramDetails(Quote existingQuote){
            
            Applicable_Offer__c applicableOffer = [SELECT Offer__c 
                                                    FROM Applicable_Offer__c 
                                                    WHERE id =: existingQuote.Applicable_Offers__c LIMIT 1
                                                    ] ;

            Offer__c offerRecord = [SELECT Program__c,Program__r.Asset_Program__c FROM Offer__c WHERE id =: applicableOffer.Offer__c LIMIT 1];
            string assetProgId = offerRecord.Program__r.Asset_Program__c;
            offer_programId = offerRecord.Program__c;

            return [SELECT Product__c,Product__r.name,ITAD_Product__r.name, ITAD_Product__c, Is_Active__c 
                    FROM Asset_Program_Detail__c WHERE
                    Asset_Program__c =: assetProgId];       

        }
        
        private Quote getCopiedQuote(string copiedQuoteId){
            
            return [SELECT id,Name,Accountid,Status,Opportunityid,Applicable_Offers__c,Applied_Purchase_Option__c,
                                            Auto_Decision__c,Comments__c,Insurance_Amount__c,
                                            Accumulated_Service__c,
                                            Credit_Report_URL__c,Decision_Maker__c,Frequency__c,
                                            Interest__c,Manual_Decision__c,Quote_Rate__c, Payment_Timing__c,
                                            Revenue__c,Term__c,Valid_From__c,Valid_To__c, ITAD_Category__c,
                                            Rental_Amount__c,Financed_Amount__c,Nominal_Interest_Rate__c,
                                            Future_Value__c,Rent_Per_Month__c,
                                            (SELECT id,Product2id,Discount,Quoteid,PricebookEntryId, 
                                            TotalPrice,ListPrice,Description,UnitPrice,Quantity,
                                            Insurance_Code__c,Insurance_Rate__c,ITAD_Fee__c,Maintenance_Amount__c,
                                            Primary__c,Residual_Value_Rate__c ,Financed_Amount__c, Periodic_Amount__c
                                            FROM QuoteLineItems)
                                            FROM Quote 
                                            WHERE id =: copiedQuoteId LIMIT 1];
        }
        
        private List<Quote> getRelatedQuotes(Quote copiedQuoteDetails){
            
            return [SELECT name,QuoteNumber FROM Quote
                                            WHERE Opportunityid =: copiedQuoteDetails.Opportunityid 
                                            ORDER BY QuoteNumber DESC];
        }

        private List<Asset_Program_Detail__c> getAssetProgramDetails(Id assetProgramId, List<Id> productIds) {
            return [
                SELECT  Id, Is_RV_Applicable__c, Product__c, Product__r.Name, Product__r.Family, Product__r.Brand__c, 
                        RV_Category_1__c, RV_Category_2__c, RV_Category_3__c, RV_Category_4__c, RV_Category_5__c, 
                        RV_Priority_1__c, RV_Priority_2__c, RV_Priority_3__c, RV_Priority_4__c, RV_Priority_5__c,
                        Insurance__c, ITAD_Product__r.Name,
                        Default_Purchase_Option__c,Max_Purchase_Option__c,Min_Purchase_Option__c
                FROM    Asset_Program_Detail__c
                WHERE   Asset_Program__c =: assetProgramId 
                AND     (Product__r.Family = :Constants.SOFT_COST_PRODUCT_TYPE OR Product__r.Family = :Constants.ASSET_HARD_PRODUCT_TYPE 
                         OR Product__r.Family = :Constants.ASSET_SOFT_PRODUCT_TYPE OR Product__r.Family = :Constants.INSTALLATION_PRODUCT_TYPE
                         OR Product__r.Family = :Constants.LICENCE_PRODUCT_TYPE)
                AND     Product__c IN :productIds        
            ];
        }

    }    

    /**Wrapper classes used to form the json structure and show the data on the page**/
    public class OffertoQuoteCls{
        @AuraEnabled
        public string uid;
        @AuraEnabled
        public string offerId;
        @AuraEnabled
        public string term;
        @AuraEnabled
        public string frequency;
        @AuraEnabled
        public string interest;
        @AuraEnabled
        public string curencycode;
        @AuraEnabled
        public string paymentTiming;
        @AuraEnabled
        public string itadLevel;
        public integer insurancePayments;
        public double accumulatedService;
        public string operation = '';
        @AuraEnabled
        public Boolean viewRentPerMonth;
        
        @AuraEnabled
        public String purchaseOption;
    }

    public class ProdtoquoteCls{
        @AuraEnabled
        public string uid;
        @AuraEnabled
        public string product;
        @AuraEnabled
        public string specification;
        @AuraEnabled
        public string quantity;
        @AuraEnabled
        public string unitprice;       
        @AuraEnabled
        public string totalprice;
        @AuraEnabled
        public string curencycode;
        @AuraEnabled
        public string operation;
        @AuraEnabled
        public string quotelineid;
        @AuraEnabled
        public string productname;
        @AuraEnabled
        public string productType;
        public double residualValue;
        public double insuranceAmount;
        public string assetModelId;
        public double financeAmount;
        public double periodicAmount;
        @AuraEnabled
        public string insuranceRate;   
        @AuraEnabled
        public string rvRate; 
        
        public ProdtoquoteCls(){}
        public ProdtoquoteCls(string quantity,string unitprice,string totalprice,string productname,string specification, string productType){       
           
            this.quantity = quantity;
            this.unitprice = unitprice;
            this.totalprice = totalprice;
            this.productname = productname;
            this.specification = specification;
            this.productType = productType;
        }  
        
        public ProdtoquoteCls(string quantity,string unitprice,string totalprice,string productname,string specification, string productType, string insuranceRate, string rvRate){       
           
            this.quantity = quantity;
            this.unitprice = unitprice;
            this.totalprice = totalprice;
            this.productname = productname;
            this.specification = specification;
            this.productType = productType;
            this.insuranceRate = insuranceRate;
            this.rvRate = rvRate;
        }
    }

    public class ServicertoquoteCls{
        @AuraEnabled
        public string uid;
        @AuraEnabled
        public string product;
        @AuraEnabled
        public string quantity;
        @AuraEnabled
        public string unitprice;
        @AuraEnabled
        public string totalprice;
        @AuraEnabled
        public string curencycode;
        @AuraEnabled
        public string operation;
        @AuraEnabled
        public string quotelineid;
        @AuraEnabled
        public string serviceName;
        public double maintAmount;
        public double periodicAmount;

        public ServicertoquoteCls() {}

        public ServicertoquoteCls(String quantity, String unitprice, String totalprice, String serviceName) {
            this.quantity = quantity;
            this.unitprice = unitprice;
            this.totalprice = totalprice;
            this.serviceName = serviceName;
        }
        
    }

    public class QuoteFinanceRateAmountCls {
        @AuraEnabled
        public string financeAmount;
        @AuraEnabled
        public string rentalAmount;
        @AuraEnabled
        public string nominalInterestRate;
        @AuraEnabled
        public string futureValue;
    }

    public class OfferCls{
        @AuraEnabled
        public string offerid;
        @AuraEnabled
        public string offerName;
        @AuraEnabled
        public string termsOption;
        @AuraEnabled
        public boolean termRange;
        @AuraEnabled
        public string defaultTerm;
        @AuraEnabled
        public string freqOptions;
        @AuraEnabled
        public string defaultFreq;
        @AuraEnabled
        public string intOptions;
        @AuraEnabled
        public string defaultInt;  
        @AuraEnabled
        public string paymentTiming;
        @AuraEnabled
        public string defaultcurncy;
        @AuraEnabled
        public string programId;
        @AuraEnabled
        public string applicableOfferId;
        @AuraEnabled
        public boolean isItadApplicable;
        @AuraEnabled
        public string itadLevel;
        @AuraEnabled
        public string rvType;
        
    }
    public class ProductCls{
        @AuraEnabled
        public string prodid;
        @AuraEnabled
        public string prodName;
        @AuraEnabled
        public string productType;
        @AuraEnabled
        public string prodDesc;
        @AuraEnabled
        public string quantity;
        @AuraEnabled
        public string unitprice;
        @AuraEnabled
        public string totalprice;
        @AuraEnabled
        public string operation;
        @AuraEnabled
        public string quotelineid;
        @AuraEnabled
        public boolean isProductAvailable; 
        @AuraEnabled
        public string insuranceRate;   
        @AuraEnabled
        public string rvRate;
        
        @AuraEnabled
        public boolean isPurchaseOptionAvailable; 
        
        @AuraEnabled
        public boolean isInsuranceAvailable; 
    }

    public class ServiceCls{
        @AuraEnabled
        public string serviceId;
        @AuraEnabled
        public string serviceName;
        @AuraEnabled
        public string productType;
        @AuraEnabled
        public string serviceDesc;
        @AuraEnabled
        public string quantity;
        @AuraEnabled
        public string unitprice;
        @AuraEnabled
        public string totalprice;
        @AuraEnabled
        public string operation;
        @AuraEnabled
        public string quotelineid;
        @AuraEnabled
        public boolean isProductAvailable;
    }

    public class OpportunityCls{
        @AuraEnabled
        public string opptyName;
        @AuraEnabled
        public string opptyId;
        @AuraEnabled
        public string customer;
        @AuraEnabled
        public string rent;
        @AuraEnabled
        public string financedAmount;
        @AuraEnabled
        public string status;
        @AuraEnabled
        public string term;
        @AuraEnabled
        public string lastmodifieddate;
        @AuraEnabled
        public string creditExpDate;
    }

    public class TableWrapperCls{
        @AuraEnabled
        public list<OfferCls> offrcls;
        @AuraEnabled
        public list<ProductCls> prdCls;
        @AuraEnabled
        public list<ServiceCls> srvCls;
        @AuraEnabled
        public String contactId;
        @AuraEnabled
        public String opptyName;
        @AuraEnabled
        public string opptyOwnerName;
        @AuraEnabled
        public string quoteid;
        @AuraEnabled
        public integer totalFinanceVal;
        @AuraEnabled
        public integer rentalVal;
        @AuraEnabled
        public string nominalInterestRate;
        @AuraEnabled
        public string totalMonthlyVal;
        @AuraEnabled
        public string restQuotes;
        @AuraEnabled
        public string latestQuote;
        @AuraEnabled
        public string quoteStatus;
        @AuraEnabled
        public date validTo;
        @AuraEnabled
        public date validFrom;
        @AuraEnabled
        public integer accumulatedService;  
        @AuraEnabled
        public list<OpportunityCls> oppClsList;   
        @AuraEnabled
        public String accountId;
        @AuraEnabled
        public String accountRegionCode;
        @AuraEnabled
        public String offerCurency; 
        @AuraEnabled
        public string myOppListViewId;
        @AuraEnabled
        public string twCurrentUserLocale;
        @AuraEnabled
        public string newOppIdWhenQtPgDirectlyOpen;
        @AuraEnabled
        public string clonedQuoteName;
        @AuraEnabled
        public string clonedQuoteNumber;
        @AuraEnabled
        public string baseRate;
        @AuraEnabled
        public string offerPaymentFreqncy;
        @AuraEnabled
        public string offerPaymentTiming;
        @AuraEnabled
        public String programId;
        @AuraEnabled
        public String applicableOfferId;
        @AuraEnabled
        public String partnerName;
        @AuraEnabled
        public String partnerEmail;
        @AuraEnabled
        public String opportunityId;
        @AuraEnabled
        public SubmitAppWrapperCls submitAddWrapper;
        @AuraEnabled
        public boolean isDocumentQstnExist;
        @AuraEnabled
        public integer insuranceAmount;
        @AuraEnabled
        public string infoMessage;
        @AuraEnabled
        public Decimal futureValue;
        @AuraEnabled
        public Decimal downpayment;
        @AuraEnabled
        public Boolean viewRentPerMonth;
        @AuraEnabled
        public Boolean appliedPR;
        @AuraEnabled
        public Boolean disabledCalculationParams;
    }

    public class SubmitAppWrapperCls{
        @AuraEnabled
        public string oppOwner;
        @AuraEnabled
        public string programBU;
        @AuraEnabled
        public string oppCreationDate;
        @AuraEnabled
        public string financialProductName;
        @AuraEnabled
        public string offerName;
        @AuraEnabled
        public string oppCurrency;
        @AuraEnabled
        public string qouteTerm;
        @AuraEnabled
        public string paymentFrequency;
        @AuraEnabled
        public string advanceArrear;
        @AuraEnabled
        public string oppFinancedAmount;
        @AuraEnabled
        public string nominalInterestRate;
        @AuraEnabled
        public list<ProdtoquoteCls> productInfoList;
        @AuraEnabled
        public list<ServicertoquoteCls> servicesInfoList;
        @AuraEnabled
        public string newQuoteDetailsStr;
        
       

        public SubmitAppWrapperCls(string oppOwner,string programBU,string oppCreationDate,string financialProductName,string offerName,string oppCurrency,string qouteTerm,string paymentFrequency,string advanceArrear,string oppFinancedAmount,string nominalInterestRate,list<ProdtoquoteCls> productInfoList, list<ServicertoquoteCls> servicesInfoList, string newQuoteDetailsStr){
            this.oppOwner = oppOwner;
            this.programBU = programBU;
            this.oppCreationDate = oppCreationDate;
            this.financialProductName = financialProductName;
            this.offerName = offerName;
            this.oppCurrency = oppCurrency;
            this.qouteTerm = qouteTerm;
            this.paymentFrequency = paymentFrequency;
            this.advanceArrear = advanceArrear;
            this.oppFinancedAmount = oppFinancedAmount;
            this.nominalInterestRate = nominalInterestRate;
            this.productInfoList = productInfoList;
            this.newQuoteDetailsStr = newQuoteDetailsStr;
            this.servicesInfoList = servicesInfoList;
        }
        public SubmitAppWrapperCls(){}
    }

    public class SearchInputWrapper {
        public String searchTerm;
        public String objectKey;
        public List<String> selectedIds;
        public String tableName;
        public String offerId;
        public Id behaveOnUserId; 
    }

    public class RateDetails {
        public String rateName;
        public Double rateValue;
        public Double costOfFunds;
    }

    public class RVandInsuranceDetails {
        public String productId;
        public String productName;
        public RVDetails residualValue;
        public insuranseDetails insurance;
    }

    public class RVDetails {
        public String rvMatrixName;
        public String category;
        //public Double value;
        public Double minRV;
        public Double maxRV;
    }

    public class InsuranseDetails {
        public String code;
        //public Double value;
        public Double minMargin;
        public Double maxMargin;
    }

   /* public class ProductInfo {
        public Id productId;
        public Decimal financialAmount;
    }*/

    public class QuoteSetupControllerException extends Exception {}
}