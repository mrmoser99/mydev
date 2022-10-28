/**
 * Test class for creating all test data 
 * 
 * Version 1.0
 * 
 */
@isTest
public without sharing class TestDataFactory {

    private static final String ACCOUNT_VENDOR_RECORDTYPE_DEVELOPER_NAME = 'Vendor';
    private static final String RETAIL_OPPORTUNITY_RECORDTYPE_DEVELOPER_NAME = System.Label.Retail;
    
    private Account vendorAccount;
    private Opportunity partnerDealOpportunity;
    private Quote quote;
    private Region__c region;
    private Term__c term;
    private Rate__c rate;
    private Margin_Matrix__c marginMatrix;
    private Rate_Line_Item__c rateLineItem;
    private Margin_Matrix_Item__c marginMatrixItem;
    private Offer__c offer;
    private Applicable_Offer__c applicableOffer;
    private Program__c program;
    private Asset_Program__c assetProgram;
    private Asset_Program_Detail__c assetProgramDetail;
    private Applicable_RV__c applicableRV;
    private RV_Matrix__c rvMatrix;
    private RV_Matrix_Line_Item__c rvLineItem;
    Product2 product;
    PricebookEntry priceBookEntry;
    
    private static TestDataFactory instance;

    public static TestDataFactory getInstance() {
        if (instance == NULL) {
            instance = new TestDataFactory();
        }

        return instance;
    }

    public TestDataFactory activatePriceBook() {
        Pricebook2 priceBook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update priceBook;

        return this;
    }

    public TestDataFactory buildVendorAccount(String name) {
        TestAccountBuilder accountVendorBuilder = new TestAccountBuilder();
        vendorAccount = accountVendorBuilder
            .withRecordType(ACCOUNT_VENDOR_RECORDTYPE_DEVELOPER_NAME)
            .withName(name)
            .withRegion(region.Id)
            .withMarginMatrix(marginMatrix.Id)
            .insertRecord(true)
            .build();

        return this;
    }

    public TestDataFactory buildPartnerDealOpportunity() {
        TestOpportunityBuilder partnerDealOpportunityBuilder = new TestOpportunityBuilder();
        partnerDealOpportunity = partnerDealOpportunityBuilder
            .withRecordType(RETAIL_OPPORTUNITY_RECORDTYPE_DEVELOPER_NAME)
            .withAccount(vendorAccount.Id)
            .insertRecord(true)
            .build();

        return this;
    }

    public TestDataFactory buildQuote(String name, Decimal amount) {
        TestQuoteBuilder quoteBuilder = new TestQuoteBuilder();
        quote = quoteBuilder
            .withopportunity(partnerDealOpportunity.Id)
            .withName(name)
            .withAmount(amount)
            .withApplicableOffer(applicableOffer.Id)
            .withQuoteRate(rate.Id)
            .insertRecord(true)
            .build();

        return this;
    }

    public TestDataFactory buildRegion(String name, String isoCode) {
        TestRegionBuilder regionBuilder = new TestRegionBuilder();
        region = regionBuilder
            .withName(name)
            .withIsoCode(isoCode)
            .insertRecord(true)
            .build();

        return this;
    }

    public TestDataFactory buildTerm(String termDimension, Integer termValue) {
        TestTermBuilder termBuilder = new TestTermBuilder();
        term = termBuilder
            .withTermDimension(termDimension)
            .withTermValue(termValue)
            .insertRecord(true)
            .build();

        return this;
    }

    public TestDataFactory buildTerms(Integer termsNumber, String termDimension, Integer termValue) {
        TestTermBuilder termBuilder = new TestTermBuilder();
        List<Term__c> terms = new List<Term__c>();
        for(Integer i = 0; i < termsNumber; i++) {
            terms.add(termBuilder
                .withTermDimension(termDimension)
                .withTermValue(termValue + i)
                .insertRecord(false)
                .build()
            );
        }
        insert terms;

        return this;
    }

    public TestDataFactory buildMarginMatrix(String name) {
        TestMarginMatrixBuilder marginMatrixBuilder = new TestMarginMatrixBuilder();
        marginMatrix = marginMatrixBuilder
            .withTerm(term.Id)
            .withName(name)
            .insertRecord(true)
            .build();

        return this;
    }

    public TestDataFactory buildRate(String name, String type) {
            TestRateBuilder rateBuilder = new TestRateBuilder();
            rate = rateBuilder
                .withName(name)
                .withType(type)
                .insertRecord(true)
                .build();
    
            return this;
        }

    public TestDataFactory buildRateLineItem(Decimal value) {
        TestRateLineItemBuilder rateLineItemBuilder = new TestRateLineItemBuilder();
        rateLineItem = rateLineItemBuilder
            .withRate(rate.Id)
            .withTerm(term.Id)
            .insertRecord(true)
            .build();

        return this;
    }

    public TestDataFactory buildMarginMatrixItem(Decimal value) {
        TestMarginMatrixItemBuilder marginMatrixItemBuilder = new TestMarginMatrixItemBuilder();
        marginMatrixItem = marginMatrixItemBuilder
            .withTerm(term.Id)
            .withMarginMatrix(marginMatrix.Id)
            .withAmount(value)
            .insertRecord(true)
            .build();

        return this;
    }

    public TestDataFactory buildDefaultMarginMatrix(Integer numberOfItems) {
        List<Term__c> terms = new List<Term__c>();

        for (Integer i = 0; i < numberOfItems; i++) {
            TestTermBuilder termBuilder = new TestTermBuilder();
            term = termBuilder
                .withTermDimension('Months')
                .withTermValue(10 * (i + 1))
                .insertRecord(true)
                .build();

            terms.add(term);
        }

        TestMarginMatrixBuilder marginMatrixBuilder = new TestMarginMatrixBuilder();
        marginMatrix = marginMatrixBuilder
            .withTerm(terms[numberOfItems - 1].Id)
            .withName('Default Margin Matrix')
            .insertRecord(true)
            .build();

        for (Term__c term : terms) {
            for (Integer i = 0; i < numberOfItems; i++) {
                TestMarginMatrixItemBuilder marginMatrixItemBuilder = new TestMarginMatrixItemBuilder();
                Decimal amount = (i == numberOfItems - 1) ? null : 100 * (i + 1);
                marginMatrixItem = marginMatrixItemBuilder
                    .withTerm(term.Id)
                    .withMarginMatrix(marginMatrix.Id)
                    .withAmount(amount)
                    .withValue(i + 1)
                    .insertRecord(true)
                    .build();
            }
        }

        return this;
    }

    public TestDataFactory buildProgram(String name) {
        TestProgramBuilder programBuilder = new TestProgramBuilder();
        program = programBuilder
            .withName(name)
            .insertRecord(true)
            .build();

        return this;
    }
        

    public TestDataFactory buildOffer(String name) {
        List<Term__c> fixedTerms = new List<Term__c>();
        List<Term__c> variableTerms = new List<Term__c>();

        TestTermBuilder termBuilder = new TestTermBuilder();
        for (Integer i = 1; i <= 3; i++) {
            Term__c fixedTerm = termBuilder
                .withTermDimension('Months')
                .withAlias('Months Term')
                .withTermValue(i)
                .insertRecord(true)
                .build();
            fixedTerms.add(fixedTerm);
        }

        TestRateBuilder rateBuilder = new TestRateBuilder();
        Rate__c fixedRate = rateBuilder
            .withName('Fixed Rate')
            .withType('Fixed')
            .insertRecord(true)
            .build();

        TestRateLineItemBuilder rateLineItemBuilder;
        for (Integer i = 1; i <= 3; i++) {
            rateLineItemBuilder = new TestRateLineItemBuilder();
            rateLineItem = rateLineItemBuilder
                .withRate(fixedRate.Id)
                .withTerm(fixedTerms[i - 1].Id)
                .withValue(i)
                .insertRecord(true)
                .build();
        }

        for (Integer i = 1; i <= 3; i++) {
            termBuilder = new TestTermBuilder();
            Term__c variableTerm = termBuilder
                .withTermDimension('Days')
                .withAlias('Days Term')
                .withTermValue(i)
                .insertRecord(true)
                .build();
            variableTerms.add(variableTerm);
        }
        
        rateBuilder = new TestRateBuilder();
        Rate__c variableRate = rateBuilder
            .withName('Variable Rate')
            .withType('Variable')
            .insertRecord(true)
            .build();

        for (Integer i = 1; i <= 3; i ++) {
            rateLineItemBuilder = new TestRateLineItemBuilder();
            rateLineItem = rateLineItemBuilder
                .withRate(variableRate.Id)
                .withTerm(variableTerms[i - 1].Id)
                .withValue(i)
                .insertRecord(true)
                .build();
   
        }

        for (Term__c term : fixedTerms) {
            TestMarginMatrixItemBuilder marginMatrixItemBuilder = new TestMarginMatrixItemBuilder();
            marginMatrixItem = marginMatrixItemBuilder
                .withTerm(term.Id)
                .withMarginMatrix(marginMatrix.Id)
                .withAmount(10000 + term.Term_Value__c)
                .withValue(1)
                .insertRecord(true)
                .build();
        }

        Financial_Product__c Financial_Product = new Financial_Product__c(Name = 'Test Financial Product', Type__c = 'Core');
        insert Financial_Product;
        
        TestOfferBuilder offerBuilder = new TestOfferBuilder();
        offer = offerBuilder
            .withName(name)
            .withProgram(program.Id)
            .withFixedRate(fixedRate.Id)
            .withVariableRate(variableRate.Id)
            .withcoreFinancialProduct(Financial_Product.Id)
            .insertRecord(true)
            .build();

        return this;
    }

    public TestDataFactory buildProduct(String name, String family) {
        TestProductBuilder productBuilder = new TestProductBuilder();
        product = productBuilder.withName(name)
            .withFamily(family)
            .withRegion(region.Id)
            .insertRecord(true)
            .build();

        return this;
    }
    
    public TestDataFactory buildApplicableOffer(String name) {
        TestApplicableOfferBuilder applicableOfferBuilder = new TestApplicableOfferBuilder();
        applicableOffer = applicableOfferBuilder
            .withName(name)
            .withAccount(vendorAccount.Id)
            .withOffer(offer.Id)
            .insertRecord(true)
            .build();

        return this;
    }
    

    public Contact buildContact(String lastname,String firstname,String title,Account acc,String phone,String email){
        
        Contact cont = new Contact(
            LastName=lastname, 
            FirstName=firstname, 
            Title=title,
            Accountid=acc.id, 
            Phone=phone, Email=email
        );
       insert cont;
       return cont;
        
    }
    

    public Pricebook2 buildstandardPricebook(Id StandardPricebookId, Boolean isactive){
        Pricebook2 standardPricebook = new Pricebook2(
            Id = StandardPricebookId,
            IsActive = isactive
        );
        update standardPricebook;
        return standardPricebook;
    }
    

    public PricebookEntry buildPricebookEntry(Id standardPriceBookId,Id prod,Integer unitprice,Boolean isactive){
        PricebookEntry pbe1 = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = prod,
            UnitPrice = unitprice,
            IsActive = isactive
        );
        insert pbe1;
        return pbe1;
        
    }

    public PricebookEntry buildPricebookEntry(Id standardPriceBookId,Id prod,Integer unitprice,Boolean isactive, Boolean insertRecord){
        PricebookEntry pbe1 = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = prod,
            UnitPrice = unitprice,
            IsActive = isactive
        );
        if (insertRecord) {
            insert pbe1;
        }
        return pbe1;
        
    }


    public PricebookEntry buildPricebookEntry(Id standardPriceBookId,Id prod,Integer unitprice,Boolean isactive,String currencyisocode ){
        
         PricebookEntry pbe2 = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = prod,
            UnitPrice = unitprice,
            IsActive = isactive,
            CurrencyIsoCode=currencyisocode
        );
        insert pbe2;
        return pbe2;
        
    }

    public PricebookEntry buildPricebookEntry(Id standardPriceBookId, Id prod, Integer unitprice, Boolean isactive, String currencyisocode, Boolean insertRecord){
        PricebookEntry pbe2 = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = prod,
            UnitPrice = unitprice,
            IsActive = isactive,
            CurrencyIsoCode=currencyisocode
        );
        if (insertRecord) {
            insert pbe2;
        }
        return pbe2; 
   }

    public Offer__c buildOffer(String Name,String DefaultPaymentTiming,String DefaultPaymentFrequency,String CurrencyIsoCode,Id Program,String OfferType,
                                String DefaultBaseRate,String SelectableBaseRate,Id BaseRateVariable, Id CoreFinancialProduct, Date ValidFrom, Date ValidTill,
                              // boolean isRVApplicable, boolean isITADApplicable){
                                String rvType, boolean isITADApplicable){
                                              
      Offer__c testOffer = new Offer__c(Name=Name,Default_Payment_Timing__c=DefaultPaymentTiming,Default_Payment_Frequency__c=DefaultPaymentFrequency,
                                         CurrencyIsoCode=CurrencyIsoCode,Program__c=Program,Offer_Type__c=OfferType,
                                          Default_Base_Rate__c=DefaultBaseRate,Selectable_Base_Rate__c=SelectableBaseRate,Base_Rate_Variable__c=BaseRateVariable, Core_Financial_Product__c = CoreFinancialProduct,
                                       Valid_From__c = ValidFrom, Valid_Until__c= ValidTill, 
                                       RV_Type__c = rvType, IS_ITAD_Applicable__c = isITADApplicable);
       insert testOffer; 
       return testOffer;
        
    }
    public Offer__c buildOffer(String Name,String DefaultPaymentTiming,String DefaultPaymentFrequency,String CurrencyIsoCode,Id Program,String OfferType,
                                String DefaultBaseRate,String SelectableBaseRate,Id BaseRateVariable, Id CoreFinancialProduct, Date ValidFrom, Date ValidTill,String InsuranceDisplayOptions){
                                              
      Offer__c testOffer = new Offer__c(Name=Name,Default_Payment_Timing__c=DefaultPaymentTiming,Default_Payment_Frequency__c=DefaultPaymentFrequency,
                                         CurrencyIsoCode=CurrencyIsoCode,Program__c=Program,Offer_Type__c=OfferType,
                                          Default_Base_Rate__c=DefaultBaseRate,Selectable_Base_Rate__c=SelectableBaseRate,Base_Rate_Variable__c=BaseRateVariable, Core_Financial_Product__c = CoreFinancialProduct,
                                       Valid_From__c = ValidFrom, Valid_Until__c= ValidTill,Insurance_Display_Options__c = InsuranceDisplayOptions);
       insert testOffer; 
       return testOffer;
        
    }
    
  
	public Offer__c buildOffer(String Name,String DefaultPaymentTiming,String DefaultPaymentFrequency,String CurrencyIsoCode,Id Program,String OfferType,
                                String DefaultBaseRate,String SelectableBaseRate,Id BaseRateVariable, Id CoreFinancialProduct, Date ValidFrom, Date ValidTill){
                                              
      Offer__c testOffer = new Offer__c(Name=Name,Default_Payment_Timing__c=DefaultPaymentTiming,Default_Payment_Frequency__c=DefaultPaymentFrequency,
                                         CurrencyIsoCode=CurrencyIsoCode,Program__c=Program,Offer_Type__c=OfferType,
                                          Default_Base_Rate__c=DefaultBaseRate,Selectable_Base_Rate__c=SelectableBaseRate,Base_Rate_Variable__c=BaseRateVariable, Core_Financial_Product__c = CoreFinancialProduct,
                                       Valid_From__c = ValidFrom, Valid_Until__c= ValidTill);
       insert testOffer; 
       return testOffer;
        
    } 
    
    public Offer__c buildOffer(String Name,String DefaultPaymentTiming,String DefaultPaymentFrequency,String CurrencyIsoCode,Id Program,String OfferType,
                                String DefaultBaseRate,String SelectableBaseRate,Id BaseRateVariable, Id CoreFinancialProduct, Date ValidFrom, Date ValidTill,Boolean insertRecord){
                                              
      Offer__c testOffer = new Offer__c(Name=Name,Default_Payment_Timing__c=DefaultPaymentTiming,Default_Payment_Frequency__c=DefaultPaymentFrequency,
                                         CurrencyIsoCode=CurrencyIsoCode,Program__c=Program,Offer_Type__c=OfferType,
                                          Default_Base_Rate__c=DefaultBaseRate,Selectable_Base_Rate__c=SelectableBaseRate,Base_Rate_Variable__c=BaseRateVariable, Core_Financial_Product__c = CoreFinancialProduct,
                                       Valid_From__c = ValidFrom, Valid_Until__c= ValidTill);
                                    
       if (insertRecord) {
             insert testOffer; 
        }
        return testOffer;
    }
    

    public Opportunity buildOpportunity(String Name,String StageName,Date closedate,String Type,Id recordtypeid,Id Accountid,Integer amount,Id standardPricebook){
        
        Opportunity testopp = new Opportunity(name=Name,StageName=StageName,closedate=closedate,Type = Type,
                                               recordtypeid = recordtypeid, Accountid =  Accountid,amount=amount,pricebook2id=standardPricebook);
        insert testopp;
        return testopp;
        
    }
    

    public Quote buildQuote(String Name, String Frequency, String Interest, String Term, Id ApplicableOffersId,String Status,Integer RentalAmount,Integer FinancedAmount,
                             Decimal NominalInterestRate,String PaymentTiming,Id Opportunityid,Id standardPricebook){
                               
            Quote testQuote = new Quote(Name=Name,Frequency__c=Frequency,Interest__c=Interest,Term__c=Term,Applicable_Offers__c=ApplicableOffersId,
                                        Status=Status,Rental_Amount__c=RentalAmount,Financed_Amount__c=FinancedAmount,Nominal_Interest_Rate__c=NominalInterestRate,                               
                                         Payment_Timing__c=PaymentTiming,Opportunityid=Opportunityid,pricebook2id=standardPricebook);
            insert testQuote;
            return testQuote;
        
    }

    public QuoteLineItem buildQuoteLineItem(Integer Quantity, Id QuoteId, Id ProductId, Integer UnitPrice, Id PricebookEntryId, Boolean insertRecord){
        QuoteLineItem qli = new QuoteLineItem(Quantity=Quantity,quoteid=QuoteId,Product2id=ProductId,UnitPrice=UnitPrice,
                                                PricebookEntryId=PricebookEntryId);
        if (insertRecord) {
            insert qli;
        }
        return qli;
        
    }    
    
    public QuoteLineItem buildQuoteLineItem(Integer Quantity, Id QuoteId, Id ProductId, Integer UnitPrice, Id PricebookEntryId,
                                            String InsuranceCode,Decimal InsuranceRate,String TypeId, Decimal ITADFee, Boolean insertRecord){
        QuoteLineItem qli = new QuoteLineItem(Quantity=Quantity,quoteid=QuoteId,Product2id=ProductId,UnitPrice=UnitPrice,
                                                PricebookEntryId=PricebookEntryId,Insurance_Code__c= InsuranceCode ,
                                             Insurance_Rate__c =InsuranceRate, Type_Id__c =TypeId, ITAD_Fee__c =ITADFee);
        if (insertRecord) {
            insert qli;
        }
        return qli;
        
    } 
    
    public QuoteLineItem buildQuoteLineItem(Integer Quantity, Id QuoteId, Id ProductId, Integer UnitPrice, Id PricebookEntryId,
                                            String InsuranceCode,Decimal InsuranceRate,String TypeId, Decimal ITADFee,Decimal ResidualRate, Boolean insertRecord){
        QuoteLineItem qli = new QuoteLineItem(Quantity=Quantity,quoteid=QuoteId,Product2id=ProductId,UnitPrice=UnitPrice,
                                                PricebookEntryId=PricebookEntryId,Insurance_Code__c= InsuranceCode ,
                                             Insurance_Rate__c =InsuranceRate, Type_Id__c =TypeId, ITAD_Fee__c =ITADFee,Residual_Value_Rate__c=ResidualRate);
        if (insertRecord) {
            insert qli;
        }
        return qli;
        
    } 
    
    public QuoteLineItem buildQuoteLineItem(Integer Quantity, Id QuoteId, Id ProductId, Integer UnitPrice, Id PricebookEntryId,
                                            String InsuranceCode,Decimal InsuranceRate,String TypeId, Decimal ITADFee,Decimal ResidualRate,Decimal RentalAmount, Boolean insertRecord){
        QuoteLineItem qli = new QuoteLineItem(Quantity=Quantity,quoteid=QuoteId,Product2id=ProductId,UnitPrice=UnitPrice,
                                                PricebookEntryId=PricebookEntryId,Insurance_Code__c= InsuranceCode ,
                                             Insurance_Rate__c =InsuranceRate, Type_Id__c =TypeId, ITAD_Fee__c =ITADFee,Residual_Value_Rate__c=ResidualRate,Periodic_Amount__c=RentalAmount);
        if (insertRecord) {
            insert qli;
        }
        return qli;
        
    } 
    
    
       public Special_Terms_and_Conditions__c buildSpecialTermsAndConditions(String name, String Category, String IsProgramSpecific,Id Program,Id Region){
           Special_Terms_and_Conditions__c stc;
           
           if(IsProgramSpecific == 'Yes'){
        
             stc = new Special_Terms_and_Conditions__c(Name= name, Category__c= Category, Is_Program_Specific__c = true,
                                                                                  Program__c=Program);
           }
           else{
                stc = new Special_Terms_and_Conditions__c(Name= name, Category__c= Category, Is_Program_Specific__c = false,
                                                                                        Region__c = Region);
           }
        insert stc;
        return stc;
        
        }
    
    public Special_Terms_and_Conditions__c buildSpecialTermsAndConditions(String name, String Category, String IsProgramSpecific,Id Program,Id Region, String Type_s, String Body){
           Special_Terms_and_Conditions__c stc;
           
           if(IsProgramSpecific == 'Yes'){
        
             stc = new Special_Terms_and_Conditions__c(Name= name, Category__c= Category, Is_Program_Specific__c = true,
                                                                                  Program__c=Program, Type__c = Type_s, Body__c = Body);
           }
           else{
                stc = new Special_Terms_and_Conditions__c(Name= name, Category__c= Category, Is_Program_Specific__c = false,
                                                                                        Region__c = Region, Type__c = Type_s, Body__c = Body);
           }
        insert stc;
        return stc;
        
        }

    
      public Offer_Special_Terms_Conditions__c buildOfferSpecialTermsAndConditions(Id offer, Id SpecialTermsAndConditions){
        
        Offer_Special_Terms_Conditions__c ostc = new Offer_Special_Terms_Conditions__c(Offer__c = offer, Special_Terms_and_Conditions__c= SpecialTermsAndConditions);
        insert ostc;
        return ostc;
        
        }
    
    	public RV_Matrix__c buildrvMatrix(Id Account, Id ProgramID, String GuarantorType, Id Region){
        
        RV_Matrix__c rvMatrix = new RV_Matrix__c(Guarantor__c = Account, Program_ID__c= ProgramID,Guarantor_Type__c = GuarantorType, Region__c = Region);
        insert rvMatrix;
        return rvMatrix;
        
        }

        public RV_Matrix__c buildrvMatrix(Id Account, Id ProgramID, String GuarantorType, Id Region, Boolean insertRecord) {
            RV_Matrix__c rvMatrix = new RV_Matrix__c(Guarantor__c = Account, Program_ID__c= ProgramID,Guarantor_Type__c = GuarantorType, Region__c = Region);
            if (insertRecord) {
                insert rvMatrix;
            } 
            return rvMatrix;
        }
    
    	public RV_Matrix__c buildrvMatrix(Id Account, Id ProgramID, String GuarantorType, Boolean isProgramSpecific , Boolean insertRecord) {
            RV_Matrix__c rvMatrix = new RV_Matrix__c(Guarantor__c = Account, Program_ID__c= ProgramID,Guarantor_Type__c = GuarantorType, Program_Specific__c = isProgramSpecific);
            if (insertRecord) {
                insert rvMatrix;
            } 
            return rvMatrix;
        }

    	public RV_Matrix_Line_Item__c buildrvLineItem(Id Term, Id RVMatrix, Decimal RVValue, String Category){
        
        RV_Matrix_Line_Item__c rvLineItem = new RV_Matrix_Line_Item__c(Duration__c = Term, RV_Matrix__c= RVMatrix, RV_Value__c = RVValue, RV_Category__c= Category);
        insert rvLineItem;
        return rvLineItem;
        
        }

        public RV_Matrix_Line_Item__c buildrvLineItem(Id Term, Id RVMatrix, Decimal RVValue, String Category, Boolean insertRecord){
            RV_Matrix_Line_Item__c rvLineItem = new RV_Matrix_Line_Item__c(Duration__c = Term, RV_Matrix__c= RVMatrix, RV_Value__c = RVValue, RV_Category__c= Category);
            if (insertRecord) {
                insert rvLineItem;
            }
            return rvLineItem;
        }
    
    	public Applicable_RV__c buildapplicableRV(Id Offer, Id RVMatrix){
        
        Applicable_RV__c applicableRV = new Applicable_RV__c(Offer__c = Offer, RV_Matrix__c= RVMatrix);
        insert applicableRV;
        return applicableRV;
        
        }

        public Applicable_RV__c buildapplicableRV(Id Offer, Id RVMatrix, Boolean insertRecord){
            Applicable_RV__c applicableRV = new Applicable_RV__c(Offer__c = Offer, RV_Matrix__c= RVMatrix);
            if (insertRecord) {
                insert applicableRV;
            }
            return applicableRV;
        }
    
    	public Asset_Program__c buildassetProgram(String Name){
        
        Asset_Program__c assetProgram = new Asset_Program__c(Name = Name);
        insert assetProgram;
        return assetProgram;
        
        }
    
    	public Asset_Program_Detail__c buildassetProgramDetail(Id AssetProgram, Id BackOfficeParam, Id Insurance, Id Product, String RVCategory1, String RVCategory2, String RVCategory3, String RVCategory4, String RVCategory5, Id RVPriority1, Id RVPriority2, Id RVPriority3, Id RVPriority4, Id RVPriority5, Boolean IS_RV_Applicable){
        
        Asset_Program_Detail__c assetProgramDetail = new Asset_Program_Detail__c(Asset_Program__c = AssetProgram, BackOffice_Param__c = BackOfficeParam, Insurance__c = Insurance, Product__c = Product, RV_Category_1__c = RVCategory1, RV_Category_2__c = RVCategory2, RV_Category_3__c = RVCategory3, RV_Category_4__c = RVCategory4, RV_Category_5__c = RVCategory5, RV_Priority_1__c = RVPriority1, RV_Priority_2__c = RVPriority2, RV_Priority_3__c = RVPriority3, RV_Priority_4__c = RVPriority4, RV_Priority_5__c = RVPriority5, IS_RV_Applicable__c = IS_RV_Applicable);
        insert assetProgramDetail;
        return assetProgramDetail;
        
        }

        public Asset_Program_Detail__c buildassetProgramDetail(Id AssetProgram, Id BackOfficeParam, Id Insurance, Id Product, String RVCategory1, String RVCategory2, String RVCategory3, String RVCategory4, String RVCategory5, Id RVPriority1, Id RVPriority2, Id RVPriority3, Id RVPriority4, Id RVPriority5, Boolean IS_RV_Applicable, Boolean insertRecord){
            Asset_Program_Detail__c assetProgramDetail = new Asset_Program_Detail__c(Asset_Program__c = AssetProgram, BackOffice_Param__c = BackOfficeParam, Insurance__c = Insurance, Product__c = Product, RV_Category_1__c = RVCategory1, RV_Category_2__c = RVCategory2, RV_Category_3__c = RVCategory3, RV_Category_4__c = RVCategory4, RV_Category_5__c = RVCategory5, RV_Priority_1__c = RVPriority1, RV_Priority_2__c = RVPriority2, RV_Priority_3__c = RVPriority3, RV_Priority_4__c = RVPriority4, RV_Priority_5__c = RVPriority5, IS_RV_Applicable__c = IS_RV_Applicable);
            if (insertRecord) {
                insert assetProgramDetail;
            }
            return assetProgramDetail;        }

    
    public Asset_Program_Detail__c buildassetProgramDetail(Id AssetProgram, Id BackOfficeParam, Id Insurance, Id Product, String RVCategory1, String RVCategory2, String RVCategory3, String RVCategory4, String RVCategory5, Id RVPriority1, Id RVPriority2, Id RVPriority3, Id RVPriority4, Id RVPriority5, Boolean IS_RV_Applicable ,Boolean isQuickCalculationProduct ,Boolean insertRecord){
            Asset_Program_Detail__c assetProgramDetail = new Asset_Program_Detail__c(Asset_Program__c = AssetProgram, BackOffice_Param__c = BackOfficeParam, Insurance__c = Insurance, Product__c = Product, RV_Category_1__c = RVCategory1, RV_Category_2__c = RVCategory2, RV_Category_3__c = RVCategory3, RV_Category_4__c = RVCategory4, RV_Category_5__c = RVCategory5, RV_Priority_1__c = RVPriority1, RV_Priority_2__c = RVPriority2, RV_Priority_3__c = RVPriority3, RV_Priority_4__c = RVPriority4, RV_Priority_5__c = RVPriority5, IS_RV_Applicable__c = IS_RV_Applicable,Quick_Calculation_Product__c = isQuickCalculationProduct);
            if (insertRecord) {
                insert assetProgramDetail;
            }
            return assetProgramDetail;
        }


    public Asset_Program_Detail__c buildassetProgramDetail(Id AssetProgram, Id Product,Id ITAD_Product,Id insurance,Boolean IS_RV_Applicable,Id RVPriority1,String RVCategory1){
        
        Asset_Program_Detail__c assetProgramDetail = new Asset_Program_Detail__c(Asset_Program__c = AssetProgram,Product__c = Product,ITAD_Product__c = ITAD_Product,Insurance__c= insurance,IS_RV_Applicable__c = IS_RV_Applicable,RV_Priority_1__c = RVPriority1,RV_Category_1__c = RVCategory1);
        insert assetProgramDetail;
        return assetProgramDetail;
        
        }

    public Asset_Program_Detail__c buildassetProgramDetail(Id AssetProgram, Id Product, Id ITAD_Product, Id insurance, Boolean IS_RV_Applicable, Id RVPriority1, String RVCategory1, Boolean insertRecord){
        Asset_Program_Detail__c assetProgramDetail = new Asset_Program_Detail__c(Asset_Program__c = AssetProgram,Product__c = Product,ITAD_Product__c = ITAD_Product,Insurance__c= insurance,IS_RV_Applicable__c = IS_RV_Applicable,RV_Priority_1__c = RVPriority1,RV_Category_1__c = RVCategory1);
        if (insertRecord) {
            insert assetProgramDetail;
        }
        return assetProgramDetail;  
    }
    
    public Asset_Program_Detail__c buildassetProgramDetail(Id AssetProgram, Id Product, Id ITAD_Product, Id insurance, Boolean IS_RV_Applicable, Id RVPriority1, String RVCategory1, Boolean isQuickCalculationProduct,Boolean insertRecord){
        Asset_Program_Detail__c assetProgramDetail = new Asset_Program_Detail__c(Asset_Program__c = AssetProgram,Product__c = Product,ITAD_Product__c = ITAD_Product,Insurance__c= insurance,IS_RV_Applicable__c = IS_RV_Applicable,RV_Priority_1__c = RVPriority1,RV_Category_1__c = RVCategory1, Quick_Calculation_Product__c=isQuickCalculationProduct);
        if (insertRecord) {
            insert assetProgramDetail;
        }
        return assetProgramDetail;  
    }

    public Asset_Program_Detail__c buildassetProgramDetail(Id AssetProgram, Id BackOfficeParam, Id Product, Id ITAD_Product, Id insurance, Boolean IS_RV_Applicable, Id RVPriority1, String RVCategory1, Boolean insertRecord){
        Asset_Program_Detail__c assetProgramDetail = new Asset_Program_Detail__c(Asset_Program__c = AssetProgram, BackOffice_Param__c = BackOfficeParam, Product__c = Product,ITAD_Product__c = ITAD_Product,Insurance__c= insurance,IS_RV_Applicable__c = IS_RV_Applicable,RV_Priority_1__c = RVPriority1,RV_Category_1__c = RVCategory1);
        if (insertRecord) {
            insert assetProgramDetail;
        }
        return assetProgramDetail;  
    }
    public Asset_Program_Detail__c buildassetProgramDetail(Id AssetProgram, Id BackOfficeParam, Id Product, Id ITAD_Product, Id insurance, Boolean IS_RV_Applicable, Id RVPriority1, String RVCategory1,Boolean isQuickCalculationProduct ,Boolean insertRecord){
        Asset_Program_Detail__c assetProgramDetail = new Asset_Program_Detail__c(Asset_Program__c = AssetProgram, BackOffice_Param__c = BackOfficeParam, Product__c = Product,ITAD_Product__c = ITAD_Product,Insurance__c= insurance,IS_RV_Applicable__c = IS_RV_Applicable,RV_Priority_1__c = RVPriority1,RV_Category_1__c = RVCategory1,Quick_Calculation_Product__c = isQuickCalculationProduct);
        if (insertRecord) {
            insert assetProgramDetail;
        }
        return assetProgramDetail;  
    }

     public Asset_Program_Detail__c buildassetProgramDetail(Id AssetProgram, Id Product){
        
        Asset_Program_Detail__c assetProgramDetail = new Asset_Program_Detail__c(Asset_Program__c = AssetProgram,Product__c = Product);
        insert assetProgramDetail;
        return assetProgramDetail;
        
        }

    public Asset_Program_Detail__c buildassetProgramDetail(Id AssetProgram, Id Product, Boolean insertRecord){
        Asset_Program_Detail__c assetProgramDetail = new Asset_Program_Detail__c(Asset_Program__c = AssetProgram,Product__c = Product);
        if (insertRecord) {
            insert assetProgramDetail;
        }
        return assetProgramDetail;
        
    } 
    public Asset_Program_Detail__c buildassetProgramDetail(Id AssetProgram, Id Product,Boolean isQuickCalculationProduct ,Boolean insertRecord){
        Asset_Program_Detail__c assetProgramDetail = new Asset_Program_Detail__c(Asset_Program__c = AssetProgram,Product__c = Product,Quick_Calculation_Product__c = isQuickCalculationProduct);
        if (insertRecord) {
            insert assetProgramDetail;
        }
        return assetProgramDetail;
        
    }
	public Asset_Program_Detail__c buildassetProgramDetail(Double MinPurchaseOption,Double MaxPurchaseOption,Double Defaultpurchaseoption,Id AssetProgram, Id BackOfficeParam, Id Insurance, Id Product, String RVCategory1, String RVCategory2, String RVCategory3, String RVCategory4, String RVCategory5, Id RVPriority1, Id RVPriority2, Id RVPriority3, Id RVPriority4, Id RVPriority5, Boolean IS_RV_Applicable, Boolean insertRecord){
            Asset_Program_Detail__c assetProgramDetail = new Asset_Program_Detail__c(Min_Purchase_Option__c = MinPurchaseOption , Max_Purchase_Option__c = MaxPurchaseOption , Default_Purchase_Option__c = Defaultpurchaseoption, Asset_Program__c = AssetProgram, BackOffice_Param__c = BackOfficeParam, Insurance__c = Insurance, Product__c = Product, RV_Category_1__c = RVCategory1, RV_Category_2__c = RVCategory2, RV_Category_3__c = RVCategory3, RV_Category_4__c = RVCategory4, RV_Category_5__c = RVCategory5, RV_Priority_1__c = RVPriority1, RV_Priority_2__c = RVPriority2, RV_Priority_3__c = RVPriority3, RV_Priority_4__c = RVPriority4, RV_Priority_5__c = RVPriority5, IS_RV_Applicable__c = IS_RV_Applicable);
            if (insertRecord) {
                insert assetProgramDetail;
            }
            return assetProgramDetail;        }


    public PricebookEntry buildPricebookEntry(Id standardPriceBookId,Id prod,Integer unitprice,String currencyisocode,Boolean isactive,Decimal Data_Wiping_Fixed_Cost_Per_Unit,
                                             Decimal Reversed_Logistics_Fixed,Decimal Reversed_Logistics_Unit_Cost_11_50,Decimal Reversed_Logistics_Unit_Cost_51,
                                             Decimal Onsite_Packaging_Fixed,Decimal Onsite_Packaging_Unit_Cost_11_50,Decimal Onsite_Packaging_Unit_Cost_51,Boolean insertRecord){
        
         PricebookEntry pbe2 = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = prod,
            UnitPrice = unitprice,
            IsActive = isactive,
            CurrencyIsoCode=currencyisocode,
            Data_Wiping_Fixed_Cost_Per_Unit__c = Data_Wiping_Fixed_Cost_Per_Unit,
            Reversed_Logistics_Fixed__c =Reversed_Logistics_Fixed ,
            Reversed_Logistics_Unit_Cost_11_50__c = Reversed_Logistics_Unit_Cost_11_50,
            Reversed_Logistics_Unit_Cost_51__c = Reversed_Logistics_Unit_Cost_51,
            Onsite_Packaging_Fixed__c = Onsite_Packaging_Fixed ,
            Onsite_Packaging_Unit_Cost_11_50__c = Onsite_Packaging_Unit_Cost_11_50,
            Onsite_Packaging_Unit_Cost_51__c = Onsite_Packaging_Unit_Cost_51
             
        );
        if(insertRecord){
           insert pbe2;
         }
        return pbe2;                                       
        
    }

    public Insurance__c buildInusrance(String Name, String Code, String AssetType, Decimal Cost,Decimal MinMargin, Id Region){
        Insurance__c insurance = new Insurance__c(Name =Name, Code__c =Code ,Cost__c=Cost,Asset_Type__c=AssetType,Minimum_Margin__c=MinMargin,Region__c=Region);
        
        insert insurance;
        return insurance; 
    }
    

    public Insurance_Line_Item__c buildInusranceLineItem(Id Insurance, Id Account,Double financedAmount, Double Value){
        
     Insurance_Line_Item__c insuranceLineItem = new  Insurance_Line_Item__c(Insurance__c =Insurance, Partner__c =Account, Financial_Amount__c = financedAmount, Value__c =Value);   
          insert insuranceLineItem;
          return insuranceLineItem;
         
         
         }
    public Insurance_Line_Item__c buildInusranceLineItem(Id Insurance, Id Account,Double financedAmount, Double Value,Boolean insertRecord){
        
     Insurance_Line_Item__c insuranceLineItem = new  Insurance_Line_Item__c(Insurance__c =Insurance, Partner__c =Account, Financial_Amount__c = financedAmount, Value__c =Value);   
        if(insertRecord){
           insert insuranceLineItem;
         }
        return insuranceLineItem;
        }
    
    public Financial_Product__c buildFinancialProduct(String name, String type, Boolean insertRecord){
        
      Financial_Product__c Financial_Product = new Financial_Product__c(Name = name, Type__c = type);
        if(insertRecord){
            insert Financial_Product;
        }
       return Financial_Product;
      }
    
     public BackOffice_Param__c buildBackOfficeParam( Id AuthorizedProgram, String Value,Boolean insertRecord){
     
       BackOffice_Param__c BackOfficeParam = new BackOffice_Param__c(Authorized_Program__c=AuthorizedProgram ,Value__c = Value);
       if(insertRecord){
            insert BackOfficeParam;
        }
       return BackOfficeParam;
      }
    
    public BackOffice_Param__c buildBackOfficeParam( Id AuthorizedProgram, String Value, String Type, Boolean insertRecord){
     
       BackOffice_Param__c BackOfficeParam = new BackOffice_Param__c(Authorized_Program__c=AuthorizedProgram ,Value__c = Value, Type__c = Type);
       if(insertRecord){
            insert BackOfficeParam;
        }
       return BackOfficeParam;
      }
    
    public EmailTemplate buildEmailTemplate(String developerName, String TemplateType, String Name,Id FolderId,Boolean IsActive,Boolean insertRecord){
        
     EmailTemplate emailTemplateObj = new EmailTemplate(developerName = developerName, TemplateType= TemplateType, Name = Name,FolderId = FolderId,IsActive=IsActive);
        if(insertRecord){
            insert emailTemplateObj;
        }
       return emailTemplateObj;
      }
    
    public Attachment buildAttachment(String Name, Id ParentId, Blob body,Boolean insertRecord){
        
    	Attachment objAttach = new Attachment(Name= Name, ParentId = ParentId,body = body);
      	if(insertRecord){
            insert objAttach;
        }
       return objAttach;
      }
    
     public Document_Library__c buildDocumentLibrary(String docName, String smartCommTempName,String docType, Id progId, Boolean insertRecord){
        Document_Library__c docLibrary = new Document_Library__c(Name = docName,SmartComTemplateReference__c = smartCommTempName,Type__c=docType,Is_Program_Specific__c= true,Program__c=progId);
        if (insertRecord) {
            insert docLibrary;
        }
        return docLibrary;
        
    } 
    
     public Related_Party__c buildRelatedParty(String relatedPartyName, String amountinWords, String amount, String addressLine,String countryCode,String city, String zipCode,Id quoteID,Id oppId, String externalId, Boolean insertRecord){
        Related_Party__c relatedParty = new Related_Party__c(Name = relatedPartyName,Amount_Text__c = amountinWords,Amount__c=amount,Address_Line__c= addressLine,Country_Code__c=countryCode,City__c=city,Postal_Code__c=zipCode,Quote__c=quoteID,Opportunity__c=oppId,External_Id__c=externalId);
        if (insertRecord) {
            insert relatedParty;
        }
        return relatedParty;
        
    } 
}