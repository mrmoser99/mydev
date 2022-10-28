/*****************************************************************************************************************
* Dll on Demaind Smart Comm Utilities
* Change Log: o, q, ql1(asset), ql2(acc)
*
*  02/08/2021 - MRM Created class
*  6/30/2022 - Geetha Revised the class for PBI 579454 and PBI 538023
*******************************************************************************************************************/
public with sharing class SmartCommUtils {
    
    /************************************************************************************************************************************************
* Generated the requested document
*
* 1.  Prepare http request to smartcomm
* 2   Create json for specific document - map1....reads opportunity, quote, quote line to form request
* 3.  Encode json
* 4.  Call smartcomm
*
* batchConfigResId = document template from smartcomm
* opportunityId = id of opp to attach document to; if null no attachment;
* proposalType proposalType = CustomerProposal or DealerProposal
*
* change log:
*
* 2/8/2022 - MRM Created
*
*
* @return   return site
*****************************************************************************************************************************************************/
    @AuraEnabled
    public static String getSmartCommDoc (Integer batchConfigResId, String opportunityId, String proposalType){
        
        system.debug('batchConfig: ' + batchConfigResId);
        system.debug('opportunityId: ' + opportunityId);
        system.debug('proposal:' + proposalType);
        
        Boolean error=false;
        String ErrorMsg = null;
        HTTPResponse res1;
        ContentVersion c;
        String jsonStr;
        
        try{
            
            /********************************* Start req for call to SmartComm url *************************************** */
            RESTRequestSetting__mdt smartCommMetaData = [SELECT Body__c,DeveloperName,Endpoint__c,HeaderParameters__c,Id,Label,Language,MasterLabel,Method__c,
                                                         NamespacePrefix,QualifiedApiName,RequestBodyWrapperClassName__c,ResponseBodyWrapperClassName__c,
                                                         Timeout__c,URLParameters__c FROM RESTRequestSetting__mdt where DeveloperName in ('Smart_Comm_Doc')];
            
            String endpoint = smartCommMetaData.Endpoint__c;
            
            HttpRequest reqAPI;
            
           // if (!Test.isRunningTest())
                reqAPI = buildHttpRequest(endpoint);
            /********************************* End req for call to SmartComm url *************************************** */
            
            
            
            
            
            /************************************ Poplulate Payload  ***************************** */
            
            String jsonRequest;
            if (batchConfigResId ==  990380852 ) {
                system.debug('start mapping');
                jsonRequest = mapProposal(990380852,opportunityId,proposalType); //Returns json for proposal document'
                system.debug('jsonRequest = '+jsonRequest);
            }
            /***************************************************************************************/
            
            
            
            /**************** Start SmartComm Processing with Transaction Data JSON ***************************** */
            
            JSONSmartCommDocRequest r =  new JSONSmartCommDocRequest();
            
            r.batchConfigResId = batchConfigResId;
            //r.projectId = 990117005; //this is static
            r.transactionDataType = 'application/json';
            r.transactionRange = 1;
            //Encrypt the payload
            r.transactionData = EncodingUtil.Base64Encode(Blob.valueOf(jsonRequest));
            
            //serialze the smartcomm transaction to call smartcomm
            jsonStr = JSON.serialize(r,true);
            reqAPI.setBody(jsonStr);
            Http http1 = new Http();
            //send request
            res1 = http1.send(reqAPI);
            
            //crazy shit because of smartcomm
            system.debug('resBody = ' +res1.getBody());
            String myResponse = res1.getBody();
            myResponse = myResponse.replace('while(1);','');
            myResponse = myResponse.replace('"previewKey":null,','');
            system.debug('myResponse = ' +myResponse);
            
            //deserialize the repsone from SmartComm
            JSONSmartCommDocResponse documentEnvelope = (JSONSmartCommDocResponse) System.JSON.deserialize(myResponse,JSONSmartCommDocResponse.class);
            system.debug('documentEnvelope = ' +documentEnvelope);
            /**************************** End SmartComm Processing ***************************** */
            
            
            
            
            /***************************** Attach File to Opportunity ************************** */
            //optional attachment
            if (opportunityId != null) {
                //Attach file to objectId
                String docName = '';
                for(JSONSmartCommDocResponse.Properties allProperties : documentEnvelope.envelopes[0].masterChannel.properties){
                    if(allProperties.name == 'filename'){
                        docName = allProperties.value;
                    }
                    
                }
                ContentVersion contentVersion = new ContentVersion();
                contentVersion.ContentLocation = 'S'; // S = Stored in Salesforce
                contentVersion.PathOnClient = docName + '.pdf';
                contentVersion.Title =  docName;
                contentVersion.VersionData = EncodingUtil.base64Decode(documentEnvelope.envelopes[0].masterChannel.data);
                system.debug('version data = ' +EncodingUtil.base64Decode(documentEnvelope.envelopes[0].masterChannel.data));
                insert contentVersion;
                
                c = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = : contentVersion.id];
                
                ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
                contentDocumentLink.ContentDocumentId = c.contentDocumentId;
                contentDocumentLink.LinkedEntityId = opportunityId;
                contentDocumentLink.ShareType = 'I'; // Inferred permission
                contentDocumentLink.Visibility = 'AllUsers';
                insert contentDocumentLink;
                
            }
            
            /***************************** End Attach File to Opportunity ************************** */
            if (!Test.isRunningTest())
                if (res1.getStatusCode() != 200) {
                    ErrorMsg = 'getSmartCommDoc: ' + res1.getStatus()  + '-' + res1.getStatusCode() + res1.getBody();
                    error=true;
                    system.debug('error: ' + ErrorMsg);
                    throw new AuraHandledException(ErrorMsg);
                }
        }
        catch (Exception e) {
            if(ErrorMsg == null)
                ErrorMsg = 'Exception in getSmartCommDoc:' + string.valueOf(e) + '-' + e.getMessage() + '-' + e.getStackTraceString() + '-' + e.getLineNumber();
            error=true;
            system.debug('error: ' + e.getStackTraceString());
            //throw new AuraHandledException(ErrorMsg);
        }
        if (error)
            return null;
        else
            return c.contentDocumentId;
    }
    
    /************************************************************************************************************************************************
* mapDocId 990380852 - customer proposal document and dealer proposal document have same id

* proposalType = CustomerProposal or DealerProposal
*
* change log:
*
* 2/8/2022 - MRM Created
*
*
*****************************************************************************************************************************************************/
    public static String mapProposal(Integer batchConfigResId,String opportunityId, String proposalType){
        
        String customerComments ='';
        List<Quote> qHeaderList = getQuoteList(opportunityId);
        List<Id> optionIds = new List<Id>();
        List<Date> expDateList =  new List<Date>();
        Map<String,List<String>> commentsMap = new Map<String,List<String>>(); 
        
        JSONSmartCommProposalDoc.QuoteLines quoteLines = new JSONSmartCommProposalDoc.QuoteLines();
        JSONSmartCommProposalDoc.Forms forms= new JSONSmartCommProposalDoc.Forms();
        JSONSmartCommProposalDoc.Request request =  new JSONSmartCommProposalDoc.Request();
        List<JSONSmartCommProposalDoc.MultiFees> multifeesCommentList = new List<JSONSmartCommProposalDoc.MultiFees>();
		JSONSmartCommProposalDoc.Comments comments = new JSONSmartCommProposalDoc.Comments();     
        
        customerComments = qHeaderList.size() > 0 ? qHeaderList[0].Opportunity.Comments__c:'';
        commentsMap.put('CustomerNotes',new List<String> {customerComments});
        
        
        
        for(Quote opts:qHeaderList){
            optionIds.add(opts.Id);
        }
        Map<Id, List<Quote_Line__c>> QLMap = getAssets(optionIds);
        List<Quote_Line__c> assetList = new List<Quote_Line__c>();
        
        List<Id> assetIdList = new List<Id>();
        
        
        for(List<Quote_Line__c> tempList : QLMap.values()){
            assetList.addAll(tempList);
        }
        
        for(Quote_Line__c ql : assetList){
            assetIdList.add(ql.Id);
        }
      
        Map<Id,List<Quote_Line__c>> AccMap = getAccessories(assetIdList);
        
        //build header - there is one header in the document
        Opportunity o = [select Nickname__c
                         ,createdDate
                         ,End_User__r.Name
                         ,Opportunity_Number__c
                         ,End_User__r.Smartcomm_Logo_Code__c
                         ,Account.Name
                         ,Account.BillingCity
                         ,Account.BillingCountry
                         ,Account.BillingPostalCode
                         ,Account.BillingState
                         ,Account.BillingStreet
                         from Opportunity
                         where id = : opportunityId
                        ];
        
        //User info - for Smartcomm logo code
        
        User loggedInUS = [Select contact.account.Smartcomm_Logo_Code__c from User where Id = :UserInfo.getUserId()];
        String userLogoCode = loggedInUS.contact.account.Smartcomm_Logo_Code__c;
        
     
        List<JSONSmartCommProposalDoc.MultiQuoteLines> multiQuoteLinesList = new List<JSONSmartCommProposalDoc.MultiQuoteLines>();
        for (Quote q: qHeaderList) {
            system.debug('qHeaderList= ' +qHeaderList.size());
            //Commenting DLL notes comments
          /*  if(q.Comments__c!=null){
                if(commentsMap.containsKey('DLLNotes')){
                    //commentsMap.get('DLLNotes').add('Option' +q.Option_Number__c +': ' +q.Comments__c);
                    commentsMap.get('DLLNotes').add(q.Comments__c);
                }
                else{
                   // commentsMap.put('DLLNotes',new List<String>{'Option' +q.Option_Number__c +': ' +q.Comments__c});
                   commentsMap.put('DLLNotes',new List<String>{q.Comments__c});
           		 }
            }  */
            
            
            if(q.ExpirationDate!=null){
                expDateList.add(q.ExpirationDate);
            }
            
            
             
            List<JSONSmartCommProposalDoc.MultiAssets> multiAssetsList = new List<JSONSmartCommProposalDoc.MultiAssets>();
            JSONSmartCommProposalDoc.MultiForms multiForms= new JSONSmartCommProposalDoc.MultiForms();
            multiForms.Base64ContentPDF = '';
            multiForms.ComplexParm= '';
            multiForms.DocName = 'Price Quote_SC';
            multiForms.DocTemplateCode = '';
            multiForms.DocTemplateName = '';
            multiForms.DocType = '';
            multiForms.SeqNo = 1234;
            
            forms.MultiForms = multiForms;
            //
            
            String finType = string.isNotBlank(q.lease_type__c)?q.lease_type__c:'';
            switch ON finType{
                when 'Fair Market Value ( FMV )' {
                    finType = 'FMV';
                }
                when '$1 Buy out' {
                    finType = '$1 BO';
                }
            }
            
           
            //List<Quote_Line__c> qLineList = getQuoteLines(opportunityId);
            List<Quote_Line__c> qLineList = QLMap.get(q.Id);
            system.debug('qLineList => ' +qLineList.size());
            
            JSONSmartCommProposalDoc.MultiQuoteLines multiquoteLines = new JSONSmartCommProposalDoc.MultiQuoteLines();
            multiquotelines.Option = integer.valueOf(q.Option_Number__c);
            system.debug('updated 1');
            for(Quote_Line__c ql: qLineList) {
                JSONSmartCommProposalDoc.FinancialAttributes financialAttributes = new JSONSmartCommProposalDoc.FinancialAttributes();
                financialAttributes.PaymentFrequency = q.Payment_Frequency__c;
                financialAttributes.Term = integer.valueOf(q.Term__c);
                financialAttributes.NoAdvPayments = integer.valueOf(q.Advance_Payments__c);
                //financialAttributes.BookedResidualAmt = Integer.valueOf(ql.Booked_Residual_Amount__c);
                financialAttributes.BrokerPoints = '';
                //Geetha - quote code
                financialAttributes.PurchaseOption = finType;
                financialAttributes.InterestRate = q.Interest__c == null ? decimal.valueOf(0) : decimal.valueOf(q.Interest__c).setScale(2);
               
                
                JSONSmartCommProposalDoc.MultiFees multiDeductions = new JSONSmartCommProposalDoc.MultiFees();
                multiDeductions.Description = '';
                multiDeductions.Label = '';
                multiDeductions.Type = '';
                multiDeductions.Value = '';
                
                
                JSONSmartCommProposalDoc.Deductions deductions = new JSONSmartCommProposalDoc.Deductions();
                deductions.MultiDeductions = multiDeductions;
                
                financialAttributes.Deductions = deductions;
                
                JSONSmartCommProposalDoc.MultiAssets multiAssets = new JSONSmartCommProposalDoc.MultiAssets();
                multiAssets.AssetNo = '1';
                multiAssets.AssetDescription = ql.Make__c + '-' + ql.Model__c;
                multiAssets.AssetType = ql.Asset_Type_ITA_Class__c; //new asset type just added to database
                multiAssets.MasterAssetType = ql.Asset_Type_ITA_Class__c;
                multiAssets.Make = ql.Make__c;
                multiAssets.Model = ql.Model__c;
                multiAssets.SerialNumber = '';
                multiAssets.Condition = 'New';
                multiAssets.Quantity = integer.valueOf(ql.Number_of_Units__c);
                multiAssets.UnitCost = ql.Base_Unit_Sales_Price__c;
                multiAssets.MSRPAmount = 0.00;
                multiAssets.SalesTaxStatus = '';
                //adding BookedResidualAmt 
                multiAssets.AssetBookedResidualAmt = String.valueOf(ql.Booked_Residual_Amount__c);
				//multiAssets.AssetBookedResidualAmt       = '1111';         
                integer quantity = integer.valueOf(ql.Number_of_Units__c);
                double amt = ql.Payment_Amount__c!=null ? double.valueOf(ql.Payment_Amount__c):0.00;
                decimal assetPreTaxAmt = 0.00;
                Double accPreTaxAmt = 0.00;
                List<Quote_Line__c> acclist = AccMap.get(ql.Id);
                String accNames = '';
                Decimal sumResidualofAcc = 0.00;
                if(acclist!=null){
                  
                    
                    for(Quote_Line__c eachAcc:acclist){
                        accNames =accNames + eachAcc.Model__c +',';
                        accPreTaxAmt = (eachAcc.Payment_Amount__c!=null) ? (accPreTaxAmt + eachAcc.Payment_Amount__c) : accPreTaxAmt + 0.00;
                   		sumResidualofAcc = sumResidualofAcc + (eachAcc.Booked_Residual_Amount__c!=null ? eachAcc.Booked_Residual_Amount__c : 0);
                    }
                }
                
                  multiAssets.AssetBookedResidualAmt = String.valueOf((ql.Booked_Residual_Amount__c!=null ? ql.Booked_Residual_Amount__c : 0.00) + sumResidualofAcc); 
                 if(quantity > 0){
                    assetPreTaxAmt = (amt + accPreTaxAmt) /quantity;
                }
                
                JSONSmartCommProposalDoc.PaymentSchedules paymentSchedules = new JSONSmartCommProposalDoc.PaymentSchedules();
                
                JSONSmartCommProposalDoc.MultiPymntSched_Z multiPymntSched = new JSONSmartCommProposalDoc.MultiPymntSched_Z();
                multiPymntSched.NumberPayments = integer.valueOf(q.Term__c);
                multiPymntSched.PreTaxPaymentAmount = assetPreTaxAmt.setScale(2);
                multiPymntSched.StreamSalesTax = 0.0;
                
                //Geetha - quote code
                JSONSmartCommProposalDoc.PaymentSchedules_Z paymentSch = new JSONSmartCommProposalDoc.PaymentSchedules_Z();
                paymentSch.MultiPymntSched = multiPymntSched;
                //financialAttributes.PaymentSchedules = paymentSch;
                MultiAssets.PaymentSchedules  = paymentSch;
                multiquotelines.FinancialAttributes = financialAttributes;
                
                JSONSmartCommProposalDoc.MultiAddOns multiAddOns = new JSONSmartCommProposalDoc.MultiAddOns();
                multiAddOns.RelatedAsset = '';
                multiAddons.Accessory = accNames.removeEnd(',');
                multiAddons.AccRateType = '';
                multiAddons.AccUnitPrice = 0.00;
                multiAddons.RelatedAsset = '';
                
                List<JSONSmartCommProposalDoc.MultiAddOns> multiAddOnsList = new LIst<JSONSmartCommProposalDoc.MultiAddOns>();
                multiAddOnsList.add(multiAddons);
                
                JSONSmartCommProposalDoc.AddOns addOns= new JSONSmartCommProposalDoc.AddOns();
                addOns.MultiAddOns = multiAddOnsList;
                
                multiAssets.AssetNo = '1';
                multiAssets.Addons = addOns;
                
                JSONSmartCommProposalDoc.Locations locations = new JSONSmartCommProposalDoc.Locations();
                JSONSmartCommProposalDoc.MultiLocations multiLocations = new JSONSmartCommProposalDoc.MultiLocations();
                
                JSONSmartCommProposalDoc.Address address = new JSONSmartCommProposalDoc.Address();
                address.AttentionLine = '';
                address.City = '';
                address.Country = '';
                address.County = '';
                address.FullAddress = '';
                address.Line1 = '';
                address.Line2 = '';
                address.Line3 = '';
                address.Line4 = '';
                address.State = '';
                address.Zip = '';
                
                multiLocations.Address = address;
                
                locations.MultiLocations = multiLocations;
                
                List<JSONSmartCommProposalDoc.MultiFees> multiFeesList = new List<JSONSmartCommProposalDoc.MultiFees>();
                
                JSONSmartCommProposalDoc.MultiFees multiFees = new JSONSmartCommProposalDoc.MultiFees();
                multiFees.Description = '';
                multiFees.Label = 'OperatingEnvironment';
                multiFees.Type = 'AssetAttributes';
                multifees.Value = ql.Operating_Environment__c;
                
                multiFeesList.add(multiFees);
                
                multiFees = new JSONSmartCommProposalDoc.MultiFees();
                multiFees.Description = '';
                multiFees.Label = 'AnnualHours';
                multiFees.Type = 'AssetAttributes';
                multifees.Value = string.valueOf(ql.Annual_Hours__c);
                
                multiFeesList.add(multiFees);
                
                multiFees = new JSONSmartCommProposalDoc.MultiFees();
                multiFees.Description = '';
                multiFees.Label = 'BatteryIncluded';
                multiFees.Type = 'AssetAttributes';
                multifees.Value = ql.Battery_Included__c;
                
                multiFeesList.add(multiFees);
                
                //Geetha: quote code
                JSONSmartCommProposalDoc.AssetAttributes assetAttrList = new JSONSmartCommProposalDoc.AssetAttributes();
                assetAttrList.MultiAssetAttr = multiFeesList;
                multiAssets.AssetAttributes = assetAttrList;
                
                
                JSONSmartCommProposalDoc.Fees fees = new JSONSmartCommProposalDoc.Fees();
                fees.MultiFees = multiFees;
                
                multiAssetsList.add(multiAssets);
                
                JSONSmartCommProposalDoc.Assets assets = new JSONSmartCommProposalDoc.Assets();
                assets.MultiAssets = multiAssetsList;
                multiquoteLines.Assets = assets;
            }
            multiQuoteLinesList.add(multiQuoteLines);
        }
        
        expDateList.sort();
        quoteLines.MultiQuoteLines = multiQuoteLinesList;
        
        JSONSmartCommProposalDoc.QuoteHdr quoteHdr = new JSONSmartCommProposalDoc.QuoteHdr();
        quoteHdr.ProposalType = proposalType;
        //quoteHdr.QuoteDate = string.valueOf(o.createdDate);
        quoteHdr.QuoteDate = string.valueOf(Date.today());
        //quoteHdr.QuoteExpiry = string.valueOf(o.createdDate);
        quoteHdr.QuoteExpiry = expDateList.size() > 0 ? String.valueOf(expDateList[0]) : '';
        quoteHdr.QuoteName = o.Nickname__c;
        quoteHdr.QuoteNo = String.valueOf(o.Opportunity_Number__c);
        quoteHdr.QuoteReason = '';
        quoteHdr.QuoteType = '';
        
       
        
        JSONSmartCommProposalDoc.RequestDetails requestDetails = new JSONSmartCommProposalDoc.RequestDetails();
        requestDetails.SourceApplication = 'DOD';
        requestDetails.NoOfCopies = 1;
        requestDetails.GenDate = string.valueOf(date.today());
        requestDetails.DistributionMethod = '';
        requestDetails.DocGenType = 'PDF';
        requestDetails.NoOfCopies = 1;
        
        JSONSmartCommProposalDoc.Recipients recipients = new JSONSmartCommProposalDoc.Recipients();
        recipients.RecipientName = UserInfo.getFirstName() + ' ' + UserInfo.getLastName();
        recipients.RecipientType = '';
        
        requestDetails.Recipients = recipients;
        requestDetails.Forms = forms;
        
        
        JSONSmartCommProposalDoc.Address address = new JSONSmartCommProposalDoc.Address();
        address.AttentionLine = '';
        address.City = '';
        address.Country =  '';
        address.County = '';
        address.FullAddress = '';
        address.Line1 = '';
        address.Line2 = '';
        address.Line3 = '';
        address.Line4 = '';
        address.State = '';
        address.Zip = '';
        
        recipients.Address = address;
        
        for(String str : commentsMap.keySet()){
          
            switch ON str{
                when 'CustomerNotes' {
                    JSONSmartCommProposalDoc.MultiFees mf = new JSONSmartCommProposalDoc.MultiFees();
                    mf.Type = 'Comments';
                    mf.Description = 'SampleCOmment1';
                    mf.Label = 'CustomerNotes';
                    mf.Value = commentsMap.get('CustomerNotes')[0];
                    multifeesCommentList.add(mf);
                }
                //commenting DLL notes - new design
               /* when 'DLLNotes'{
                    for(Integer i=0; i<commentsMap.get('DLLNotes').size(); i++){
                        JSONSmartCommProposalDoc.MultiFees mf = new JSONSmartCommProposalDoc.MultiFees();
                        mf.Type = 'Comments';
                        mf.Description = 'SampleCOmment2';
                        mf.Label = 'DLLNotes';
                        //mf.Value = commentsMap.get('DLLNotes')[i];
                        mf.value = ''; //sending blank comments
                        multifeesCommentList.add(mf);
                    }
                   
                }*/
            }
            
           
        }
        
        comments.MultiComments = multifeesCommentList;
        
        JSONSmartCommProposalDoc.Party partyName = new JSONSmartCommProposalDoc.Party();
        List<JSONSmartCommProposalDoc.MultiParty> partyNameList = new  List<JSONSmartCommProposalDoc.MultiParty>();
        
        JSONSmartCommProposalDoc.MultiParty multiPartyName_Partner = new JSONSmartCommProposalDoc.MultiParty();
        JSONSmartCommProposalDoc.MultiParty multiPartyName_Customer = new JSONSmartCommProposalDoc.MultiParty();
        
        JSONSmartCommProposalDoc.Names pNames_Partner = new JSONSmartCommProposalDoc.Names();
        JSONSmartCommProposalDoc.Names pNames_Customer = new JSONSmartCommProposalDoc.Names();
        
        JSONSmartCommProposalDoc.MultiNames  multiPNames_Partner = new JSONSmartCommProposalDoc.MultiNames();
        JSONSmartCommProposalDoc.MultiNames  multiPNames_Customer = new JSONSmartCommProposalDoc.MultiNames();
        
        
                
        JSONSmartCommProposalDoc.Locations locName= new JSONSmartCommProposalDoc.Locations();
        JSONSmartCommProposalDoc.MultiLocations multiLoc = new JSONSmartCommProposalDoc.MultiLocations();
        JSONSmartCommProposalDoc.Address locAddress = new JSONSmartCommProposalDoc.Address();
        
        //locAddress.FullAddress = '1041 penn cir apt f204 King of Prussia PA 19333';
        locAddress.Line1 = o.Account.BillingStreet;
       // locAddress.Line2 = 'R627';
        locAddress.City = o.Account.BillingCity;
        locAddress.State = o.Account.BillingState;
        //locAddress.County = o.Account.BillingCity;
        locAddress.Country = o.Account.BillingCountry;
        locAddress.Zip = o.Account.BillingPostalCode;
        multiLoc.LocationUsage = 'PrimaryAddress';
        multiLoc.Address = locAddress;
        locName.MultiLocations = multiLoc;
        multiPartyName_Partner.Locations = locName;

        multiPNames_Partner.FullName = o.Account.Name;
        multiPNames_Partner.NameType = 'LegalName';
        pNames_Partner.MultiNames = multiPNames_Partner;
        multiPartyName_Partner.PartyType = 'Partner';
        multiPartyName_Partner.Names = pNames_Partner;
        
        if(userLogoCode!=null){
             multiPartyName_Partner.CodeLogo = userLogoCode;
        }
        
        //Code for Customer Name
        multiPartyName_Customer.PartyType = 'Customer';
        multiPNames_Customer.FullName = o.End_User__r.Name;
        multiPNames_Customer.NameType = 'LegalName';
        pNames_Customer.MultiNames = multiPNames_Customer;
        multiPartyName_Customer.Names = pNames_Customer;
       
       
        
        partyNameList.add(multiPartyName_Partner);
        partyNameList.add(multiPartyName_Customer);
        partyName.MultiParty = partyNameList;
        

        
        JSONSmartCommProposalDoc.RequestData requestData = new JSONSmartCommProposalDoc.RequestData();
        requestData.QuoteHdr = quoteHdr;
        
        requestData.QuoteLines = quoteLines;
        requestData.Comments = comments;
        requestData.Party = partyName;
        
        request.RequestData = requestData;
        request.RequestDetails = requestDetails;
        
        String payLoad = JSON.serialize(request,true);
        
        JSONSmartCommProposalDoc r = new JSONSmartCommProposalDoc();
        r.Request = request;
        system.debug('JSON.serialize= ' +JSON.serialize(r,true) );
        return JSON.serialize(r,true);
    }
    
    /************************************************************************************************************************************************
*
*****************************************************************************************************************************************************/
    public static List<Quote> getQuoteList(string opportunityId){
        
        List<Quote> includeProposalQL = new List<Quote>();
        List<Quote> qList = [SELECT
                             AccountId,
                             Advance_Payments__c,
                             Amount__c,
                             Option_Number__c,
                             Lease_Type__c,
                             Base_Unit_Sales_Price__c,
                             BillingAddress,
                             BillingCity,
                             BillingCountry,
                             BillingGeocodeAccuracy,
                             BillingLatitude,
                             BillingLongitude,
                             BillingName,
                             BillingPostalCode,
                             BillingState,
                             BillingStreet,
                             Code_URA__c,
                             Comments__c,
                             Conditions__c,
                             ContactId,
                             ContractId,
                             Credit_Report_URL__c,
                             CurrencyIsoCode,
                             //Customer_Account__c,
                             Decision_Maker__c,
                             Description,
                             Opportunity.End_User__r.phone,
                             Opportunity.End_User__c,
                             Opportunity.End_User__r.email__c,
                             Opportunity.End_User__r.BillingStreet,
                             Opportunity.End_User__r.BillingCity,
                             Opportunity.End_User__r.BillingCountry,
                             Opportunity.End_User__r.BillingState,
                             Expiration_Date__c,
                             ExpirationDate,
                             Fax,
                             End_User__c,
                             Financed_Amount__c,
                             Frequency__c,
                             GrandTotal,
                             Id,
                             Include_In_Proposal__c,
                             Name,
                             Opportunity.End_User__r.Name,
                             Opportunity.End_User_Phone__c,
                             Payment_Frequency__c,
                             Payment_Timing__c,
                             Phone,
                             Quote_Rate__c,
                             QuoteNumber,
                             QuoteToAddress,
                             QuoteToCity,
                             QuoteToCountry,
                             QuoteToGeocodeAccuracy,
                             QuoteToLatitude,
                             QuoteToLongitude,
                             QuoteToName,
                             QuoteToPostalCode,
                             QuoteToState,
                             QuoteToStreet,
                             //Rate_Type__c,
                             Reference__c,
                             Rental_Amount__c,
                             Residual__c,
                             Revenue__c,
                             Status,
                             Status_Priority__c,
                             Subtotal,
                             Term__c,
                             Total_Payment__c,
                             Total_Price__c,
                             TotalPrice,
                             Interest__c,
                             Opportunity.Comments__c
                             from Quote
                             where opportunityId = : opportunityId 
                             order by option_number__c
                            ];
        //Logic for handling - only to include if "include proposal" checkbox is checked
        
        for(Quote qt :qList){
            if(qt.Include_In_Proposal__c){
                includeProposalQL.add(qt);
            }
        }
        
        if(includeProposalQL.size() >0){
            return includeProposalQL;
        }
        else{
            return qList;
        }
    }
    

    /************************************************************************************************************************************************
*
*****************************************************************************************************************************************************/
   /* public static List<Quote_Line__c> getQuoteLines(ID opportunityId){
        
        List<Quote_Line__c> qlList = new List<Quote_Line__c>();
        qlList = [SELECT
                  Annual_Hours__c,
                  Asset_Type_ITA_Class__c,
                  Base_Unit_Sales_Price__c,
                  Battery_Included__c,
                  Chassis__c,
                  CreatedById,
                  CreatedDate,
                  CurrencyIsoCode,
                  Equipment_Type__c,
                  Id,
                  IsDeleted,
                  LastActivityDate,
                  LastModifiedById,
                  LastModifiedDate,
                  Make__c,
                  Mast_Type__c,
                  Model__c,
                  Name,
                  Number_of_Units__c,
                  Operating_Environment__c,
                  Quote__c,
                  Rate_Type__c,
                  Related_Asset__c,
                  Asset_Type_ITA_Class_Id__c,
                  SystemModstamp,
                  Payment_Amount__c,
                  Booked_Residual_Amount__c
                  FROM Quote_Line__c
                  where quote__r.opportunityId = : opportunityId
                 ];
        
        return qlList;
    } */
    
    //Geetha code for getAssets - new - start
    
    public static Map<Id,List<Quote_Line__c>> getAssets(List<Id> quoteIds){
        
        Map<Id,List<Quote_Line__c>> retAssetMap = new Map<Id,List<Quote_Line__c>>();
        
        system.debug('quoteId= ' +quoteIds);
        List<Quote_Line__c> qLineList = new List<Quote_Line__c>();
        
        List<Quote_Line__c> qlList = new List<Quote_Line__c>();
        qlList = [SELECT
                  Annual_Hours__c,
                  Asset_Type_ITA_Class__c,
                  Base_Unit_Sales_Price__c,
                  Battery_Included__c,
                 // Chassis__c,
                  CreatedById,
                  CreatedDate,
                  CurrencyIsoCode,
                  Equipment_Type__c,
                  Id,
                  IsDeleted,
                  LastActivityDate,
                  LastModifiedById,
                  LastModifiedDate,
                  Make__c,
                  Mast_Type__c,
                  Model__c,
                  Name,
                  Number_of_Units__c,
                  Operating_Environment__c,
                  Quote__c,
                 // Rate_Type__c,
                  Related_Asset__c,
                  Asset_Type_ITA_Class_Id__c,
                  SystemModstamp,
                  Payment_Amount__c,
                  Booked_Residual_Amount__c
                  FROM Quote_Line__c
                  where quote__c in : quoteIds
                  and Equipment_Type__c = 'Asset'
                 ];
        
      
        
        for(Quote_Line__c ql:qlList){
            Id parentQuote = ql.Quote__c;
            if(retAssetMap.containsKey(parentQuote)){
                List<Quote_Line__c> tempQLineList =  retAssetMap.get(parentQuote);
                tempQLineList.add(ql);
                retAssetMap.put(parentQuote, tempQLineList);
            }
            else{
                List<Quote_Line__c> tempQLineList =  new List<Quote_Line__c>();
                tempQLineList.add(ql);
                retAssetMap.put(parentQuote, tempQLineList);
            }
        }
        system.debug('retAssetMap= ' +retAssetMap);
        return retAssetMap;
    }
    
    
    //Geetha code for getAsset - new - end
    
    /////////////////////////////////////////
    
    //start - get acc
    
      
    public static Map<Id,List<Quote_Line__c>> getAccessories(List<Id> assetIds){
        
        Map<Id,List<Quote_Line__c>> retAssetMap = new Map<Id,List<Quote_Line__c>>();
        
        system.debug('assetIds= ' +assetIds);
        List<Quote_Line__c> qLineList = new List<Quote_Line__c>();
        
        List<Quote_Line__c> qlList = new List<Quote_Line__c>();
        qlList = [SELECT
                  Annual_Hours__c,
                  Asset_Type_ITA_Class__c,
                  Base_Unit_Sales_Price__c,
                  Battery_Included__c,
                 // Chassis__c,
                  CreatedById,
                  CreatedDate,
                  CurrencyIsoCode,
                  Equipment_Type__c,
                  Id,
                  IsDeleted,
                  LastActivityDate,
                  LastModifiedById,
                  LastModifiedDate,
                  Make__c,
                  Mast_Type__c,
                  Model__c,
                  Name,
                  Number_of_Units__c,
                  Operating_Environment__c,
                  Quote__c,
                  //Rate_Type__c,
                  Related_Asset__c,
                  Asset_Type_ITA_Class_Id__c,
                  SystemModstamp,
                  Booked_Residual_Amount__c,
                  Payment_Amount__c
                  FROM Quote_Line__c
                  where Related_Asset__c in : assetIds
                  and Equipment_Type__c = 'Add-on'
                  
                 ];
        
      
        
        for(Quote_Line__c ql:qlList){
            Id parentQuote = ql.Related_Asset__c;
            if(retAssetMap.containsKey(parentQuote)){
                List<Quote_Line__c> tempQLineList =  retAssetMap.get(parentQuote);
                tempQLineList.add(ql);
                retAssetMap.put(parentQuote, tempQLineList);
            }
            else{
                List<Quote_Line__c> tempQLineList =  new List<Quote_Line__c>();
                tempQLineList.add(ql);
                retAssetMap.put(parentQuote, tempQLineList);
            }
        }
        system.debug('retAccMap= ' +retAssetMap);
        return retAssetMap;
    }
    
    
    //Geetha code for getAsset - new - end
    
    
    
    //end - get acc
    
    /************************************************************************************************************************************************
* buildHTTPRequest
*
* change log:
*
* 2/8/2022 - MRM Created
*
*
* @return   httprequest
*
*****************************************************************************************************************************************************/
    public static HttpRequest buildHttpRequest(String endpoint){
        
        HttpRequest reqAPI = new HttpRequest();
        
        reqAPI.setEndpoint(endpoint);
        reqAPI.setMethod('POST');
        reqAPI.setHeader('Content-Type', 'application/json');
        reqAPI.setHeader('Accept', 'application/json');
        reqAPI.setHeader('Authorization', 'Bearer ' + getToken());
        reqAPI.setTimeout(120000);
        return reqAPI;
        
    }
    
    /************************************************************************************************************************************************
* getToken - checks cache for token.  if not found or expired, creates new token.
*
* change log:
*
* 10/10/2021 - MRM Created
*
*
* @return   token
*
*****************************************************************************************************************************************************/
    public static String getToken(){
        
        FINAL String PARTITION = 'local.DLLonDemand';
        FINAL String KEY = 'SmartCommAuthtoken';
        
        DDCacheUtilityPartition.sessionInfo s = new DDCacheUtilityPartition.sessionInfo();
        
        if (DDcacheUtilityPartition.containsKey(PARTITION,KEY)) {  //returns true or false
            s = (DDCacheUtilityPartition.sessionInfo)CacheUtilityPartition.getCachedObject(PARTITION,KEY); //returns the object in cache
            if (system.now() > s.sessionExpiration) {
                system.debug('*************************** CACHE TOKEN EXPIRED');
                
                DDCacheUtilityPartition.clearCache(PARTITION, KEY); //expired  expired  aunt problems
                
                tokenClass t = new tokenClass();
                t = getAuthToken();
                
                
                system.debug('************************************* STORED CACHE EXPIRED');
                //Create and Store new token
                s.sessionToken =  t.token;
                
                s.sessionExpiration = t.expires;
                
                DDCacheUtilityPartition.setCachedObject(PARTITION,KEY, s);
                
                return s.sessionToken;
                
            }
            else{
                system.debug('************************ FOUND CACHE' + ' ' + s.sessionToken);
                return s.sessionToken; //USE THIS TOKEN
            }
        }
        else{
            
            
            tokenClass t = new tokenClass();
            t = getAuthToken();
            
            
            //Create and Store new token
            s.sessionToken =  t.token;
            s.sessionExpiration = t.expires;
            
            system.debug('******************************** STORED CACHE' + s.sessionToken);
            DDCacheUtilityPartition.setCachedObject(PARTITION, KEY, s);
            
            return s.sessionToken;
        }
        
        
    }
    
    /************************************************************************************************************************************************
* getAuthTOken
*
* change log:
*
* 11/2/2021 - MRM Created
*
*
* @return   return token
*****************************************************************************************************************************************************/
    
    public static tokenClass getAuthToken(){
        
        
        RESTRequestSetting__mdt smartCommMetaData = [SELECT Body__c,DeveloperName,Endpoint__c,HeaderParameters__c,Id,Label,Language,MasterLabel,Method__c,
                                                     NamespacePrefix,QualifiedApiName,RequestBodyWrapperClassName__c,ResponseBodyWrapperClassName__c,
                                                     Timeout__c,URLParameters__c FROM RESTRequestSetting__mdt where DeveloperName in ('axway')];
        
        tokenClass t = new tokenClass();
        
        HttpRequest reqAPI = new HttpRequest();
        Http http = new Http();
        
        reqAPI.setEndpoint(smartCommMetaData.Endpoint__c);
        reqAPI.setMethod('POST');
        List<String> sList = smartCommMetaData.HeaderParameters__c.split(':');
        reqAPI.setHeader(sList[0],slist[1]);
        reqAPI.setBody(smartCommMetaData.Body__c);
        
        /* dev keys
reqAPI.setBody('client_id='+ 'f20ddfca-ae3a-4754-99a8-cafbe30a7b76' +
'&client_secret='+ '55e87277-0999-430b-8558-168ec41d50a9' +
'&grant_type=client_credentials' +
'&resource=https://apiacc.dllgroup.com/'
);
*/
        reqAPI.setTimeout(120000);
        
        HTTPResponse res;
        
       // if (!Test.isRunningTest())
            res = http.send(reqAPI);
        
       // if (!Test.isRunningTest())
            if(res.getStatusCode()==200 ) {
                
                JSONParser parser = JSON.createParser(res.getBody());
                //Extract the access token string  from the body
                while (parser.nextToken() != null) {
                    if((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'access_token')) {
                        parser.nextToken();
                        t.token = parser.getText();
                    }
                    
                }
                
                JSONParser parser2 = JSON.createParser(res.getBody());
                while (parser2.nextToken() != null) {
                    if((parser2.getCurrentToken() == JSONToken.FIELD_NAME) && (parser2.getText() == 'expires_in')) {
                        // Get the value.
                        parser2.nextToken();
                        String s = parser2.getText();
                        Integer sec = integer.valueOf(s);
                        dateTime d = system.now().addSeconds(sec);
                        t.expires = d;
                        
                        
                    }
                }
            }
        else {
            t.token  = '12333';
        }
        
        return t;
        
    }
    
    public class tokenClass {
        public String token;
        
        public dateTime expires;
    }
    
   
}