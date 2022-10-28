/**
 * This class is used in RESTCallout service class to handle callout response. 
 * It provides request body wrapper for Submit Application callout
 * 
 * Class uses JSONGenerator class methods to generate standard JSON-encoded content.
 * 
 * Version 1.0 @author Elena Sokolova @date 2021-01-15
 * Version 1.1 @author Neha Tyagi @date 2021-05-17 (Cashflow in Asset)
 * Version 1.2 @author Ravisha Chugani @date 2021-07-06 (SoftCost and Maintanence)
 * Version 1.3 @author Ravisha Chugani @date 2021-07-15 (Issue Fee, Invoice Fee and Extension Rent)
 * Version 1.4 @author Anujit @date 2021-07-15 US#505177
 * Version 1.5 @author Ravisha Chugani @date 2021-08-23 
 */
public with sharing class SubmitApplicationRequestBodyWrapper extends BaseRequestBodyWrapper {

    private JSONGenerator gen;

    public override void init(Map<String, Object> params) {
    
        
    //Create a JSONGenerator object
    // Pass true to the costructor for pretty print formatting
    gen = JSON.createGenerator(true);
        // write data to the JSON string
        // write the starting marker of a JSON object '{'
        gen.writeStartObject();
            // write a field name and value pairs using specified field name and  value with certain data type
            gen.writeStringField('contractNumber', (String) params.get('contractNumber'));
            gen.writeStringField('id', (String) params.get('id'));
            gen.writeStringField('submittedBy', (String) params.get('submittedBy'));
            gen.writeStringField('invoiceReference', (String) params.get('reference'));
            gen.writeStringField('owner', (String) params.get('owner'));
            gen.writeStringField('origSystem', 'WCRM'); //Hardcoded
            gen.writeStringField('country', (String) params.get('programCountry'));
            gen.writeStringField('accountName', (String) params.get('accountName'));
            gen.writeStringField('businessUnit', (String) params.get('businessUnit'));
            gen.writeDateTimeField('creationDate', (Datetime) params.get('creationDate'));
            gen.writeStringField('extensionCode', (String) params.get('extensionCode'));
            gen = buildPartiesJSON((List<Map<String, Object>>) params.get('parties'), gen);
            gen = buildLesseeJSON((Map<String, Object>) params.get('lessee'), gen);
            gen = builFinanceStructureJSON((Map<String, Object>) params.get('financeStructure'), gen);
            gen = buildAssetsJSON((List<Map<String, Object>>) params.get('assets'), gen);
            gen = buildadditionalAccountSettingsJSON((List<Map<String, Object>>) params.get('additionalAccountSettings'), gen);
            gen = buildsoftcostJSON((List<Map<String, Object>>) params.get('softcost'), gen);
            
            if(params.get('contractConditions') != null){
                gen = buildcontractConditionsJSON((Map<String, Object>) params.get('contractConditions'), gen);
            }
        // write the ending marker of a JSON object '}'    
        gen.writeEndObject();
    }

    /**
     * Method gets request body as a generated JSON string
     */
    public override String getRequestBodyAsString() {

        return gen.getAsString();
    }

    @TestVisible
    private static JSONGenerator buildPartiesJSON(List<Map<String, Object>> parties, JSONGenerator gen) {

        gen.writeFieldName('parties');
        gen.writeStartArray();
            for (Map<String, Object> party : parties) {
                gen.writeStartObject();
                    gen.writeStringField('partyType', 'dealer'); //Hardcoded for Phase 1
                    gen = buildDataJSON((Map<String, Object>) party.get('data'), gen);
                gen.writeEndObject();
            }
        gen.writeEndArray();

        return gen;
    }

    @TestVisible
    private static JSONGenerator buildDataJSON(Map<String, Object> data, JSONGenerator gen) {
        gen.writeFieldName('data');
        gen.writeStartObject();
        gen.writeStringField('name', (String) data.get('name'));
        gen.writeStringField('dealerSalesPersonCode', (String) data.get('dealerSalesPersonCode'));
        gen = buildIdentificationJSON((List<Map<String, Object>>) data.get('identification'), gen);
        gen = buildContactJSON((List<Map<String, Object>>) data.get('contact'), gen);
        gen.writeEndObject();

        return gen;
    }


    @TestVisible
    private static JSONGenerator buildAddressJSON(Map<String, Object> address, JSONGenerator gen) {

        gen.writeFieldName('address');
        gen.writeStartObject();
            gen.writeStringField('street', (address.get('street') != null ? (String) address.get('street') : 'string'));
            gen.writeStringField('city', address.get('city') != null ? (String) address.get('city') : 'string');
            gen.writeStringField('postalCode', (String) address.get('postalCode') != null ? (String) address.get('postalCode') : 'string');
            gen.writeStringField('country', address.get('country') != null ? (String) address.get('country') : 'string');
        gen.writeEndObject();

        return gen;
    }

    @TestVisible
    private static JSONGenerator buildIdentificationJSON(List<Map<String, Object>> identifications, JSONGenerator gen) {

        gen.writeFieldName('identification');
        gen.writeStartArray();
            for (Map<String, Object> identification : identifications) {
                gen.writeStartObject();
                    gen.writeStringField('identifier', (String) identification.get('identifierValue'));
                    gen.writeStringField('identifierType', (String) identification.get('identifierType'));
                gen.writeEndObject();
            }
        gen.writeEndArray();

        return gen;
    }
    
    @TestVisible
    private static JSONGenerator buildContactJSON(List<Map<String, Object>> contacts, JSONGenerator gen) {

        gen.writeFieldName('contact');
        gen.writeStartArray();
            for (Map<String, Object> contact: contacts) {
                gen.writeStartObject();
                    gen.writeStringField('name', (String) contact.get('name'));
                    gen.writeStringField('email', (String) contact.get('email'));
                gen.writeEndObject();
            }
        gen.writeEndArray();

        return gen;
    }

    @TestVisible
    private static JSONGenerator buildLesseeJSON(Map<String, Object> params, JSONGenerator gen) {

        gen.writeFieldName('lessee');        	
            gen.writeStartObject();
            gen.writeStringField('legalEntity', (String) params.get('soloTraderLegalName'));
            gen = buildIdentificationJSON((List<Map<String, Object>>) params.get('identification'), gen);
            gen.writeStringField('name', params.get('name') != null ? (String) params.get('name') : 'string');
            gen = buildAddressJSON((Map<String, Object>) params.get('address'), gen);
            if(!((Map<String, Object>) params.get('contact')).isEmpty()){
                gen = buildLesseeContactJSON((Map<String, Object>) params.get('contact') , gen);
            }
            if(params.get('invoicingInfo')!=null){
                gen = buildInvoicingInfoJSON((Map<String, Object>) params.get('invoicingInfo') , gen);           
            }
            if(params.get('ultimateBeneficiaries')!=null && !((List<Map<String, Object>>)params.get('ultimateBeneficiaries')).isEmpty()){
                gen = buildUltimateBeneficiariesJSON((List<Map<String, Object>>) params.get('ultimateBeneficiaries') , gen);
            }
        gen.writeEndObject();

        return gen;
    }
    
    @TestVisible
    private static JSONGenerator buildLesseeContactJSON(Map<String, Object> contact, JSONGenerator gen) {

        gen.writeFieldName('contact');
        gen.writeStartArray();
           gen.writeStartObject();
               gen.writeStringField('name', (String) contact.get('name'));
               gen.writeStringField('email', (String) contact.get('email'));
               gen = buildPhoneNumbersJSON((Map<String, Object>) contact, gen);
            gen.writeEndObject();
        gen.writeEndArray();
        
        return gen;
    }
    
    @TestVisible
    private static JSONGenerator buildPhoneNumbersJSON(Map<String, Object> numbers, JSONGenerator gen) {

        gen.writeFieldName('phoneNumbers');
        gen.writeStartArray();
            gen.writeStartObject();
            gen.writeStringField('type', (String) numbers.get('type'));
            gen.writeStringField('number', (String) numbers.get('number'));
            gen.writeEndObject();
        gen.writeEndArray();

        return gen;
    }    
   
    @TestVisible
    private static JSONGenerator buildInvoicingInfoJSON(Map<String, Object> invoiceInfo, JSONGenerator gen) {

        gen.writeFieldName('invoicingInfo');
           gen.writeStartObject();
               gen.writeStringField('invoiceMethod', (String) invoiceInfo.get('invoiceMethod'));
               
                if('paper'.equals((String) invoiceInfo.get('invoiceMethod'))){
                    gen = buildInvoiceAddressJSON((Map<String, Object>) invoiceInfo, gen);
                }
                else if('e-invoicing'.equals((String) invoiceInfo.get('invoiceMethod')))
                {
                    gen.writeStringField('email', (String) invoiceInfo.get('email'));
                }
                else{
                    gen.writeStringField('ediType', (String) invoiceInfo.get('ediType'));
                    gen.writeStringField('ediReference', (String) invoiceInfo.get('ediReference'));
                }
               
            gen.writeEndObject();
        
        return gen;
    }
    
    @TestVisible
    private static JSONGenerator buildInvoiceAddressJSON(Map<String, Object> address, JSONGenerator gen) {

        gen.writeFieldName('address');
            gen.writeStartObject();
            gen.writeStringField('street', (String) address.get('street'));
            gen.writeStringField('city', (String) address.get('city'));
            gen.writeStringField('postalCode', (String) address.get('postalCode'));
            gen.writeStringField('country', (String) address.get('country'));
            gen.writeStringField('department', (String) address.get('department'));
            gen.writeEndObject();

        return gen;
    }
    
    @TestVisible
    private static JSONGenerator buildUltimateBeneficiariesJSON(List<Map<String, Object>> ultimateBeneficiaries, JSONGenerator gen) {

        gen.writeFieldName('ultimateBeneficiaries');
        gen.writeStartArray();
            
                gen = buildIndividualJSON((List<Map<String, Object>>) ultimateBeneficiaries, gen);
           
        gen.writeEndArray();

        return gen;
    }
    
    @TestVisible
    private static JSONGenerator buildIndividualJSON(List<Map<String, Object>> individual, JSONGenerator gen) {

        
            for (Map<String, Object> individuals : (List<Map<String, Object>>) individual) {
                gen.writeStartObject();
                gen.writeFieldName('individual');
                gen.writeStartObject();
                    gen.writeStringField('givenName', (String) individuals.get('givenName'));
                    gen.writeStringField('familyName', (String) individuals.get('familyName'));
                    gen.writeStringField('middleName', (String) individuals.get('middleName'));
                    gen.writeStringField('birthDate', (String) individuals.get('birthDate'));
                    gen.writeStringField('countryOfBirth', (String) individuals.get('countryOfBirth'));
                gen.writeEndObject();
                gen.writeEndObject();
            }

        return gen;
    }

    @TestVisible
    private static JSONGenerator builFinanceStructureJSON(Map<String, Object> financeStructure, JSONGenerator gen) {

        gen.writeFieldName('financeStructure');
        gen.writeStartObject();
            gen = buidFinancialProductJSON((Map<String, Object>) financeStructure.get('financialProduct'), gen);
            gen.writeDateTimeField('startDate', (Datetime) financeStructure.get('startDate'));
            gen.writeDateTimeField('endDate', (Datetime) financeStructure.get('endDate'));
            gen.writeStringField('currency', (String) financeStructure.get('currency'));
            gen.writeNumberField('numberOfMonths', (Integer) financeStructure.get('numberOfMonths'));
            //gen.writeStringField('paymentFrequency', 'monthly');
            gen.writeStringField('paymentFrequency', (String) financeStructure.get('paymentFrequency'));
            gen.writeStringField('paymentTiming', (String) financeStructure.get('paymentTiming'));
            gen.writeStringField('interestBase', (String) financeStructure.get('interestBase'));
            gen.writeNumberField('interestBaseRate', (Decimal) financeStructure.get('interestBaseRate'));
         	gen.writeNumberField('periodicPaymentAmount', (Decimal) financeStructure.get('periodicPaymentAmount'));
            if(financeStructure.containskey('insuranceMode')){
                gen.writeNumberField('insuranceMode', (Integer) financeStructure.get('insuranceMode'));
            }
            gen = buildFinanceJSON((Map<String, Object>) financeStructure.get('finance'), gen);
        gen.writeEndObject();

        return gen;
    }


    @TestVisible
    private static JSONGenerator buidFinancialProductJSON(Map<String, Object> financialProduct, JSONGenerator gen) {

        gen.writeFieldName('financialProduct');
        gen.writeStartObject();
            gen.writeStringField('financialProductType', (String) financialProduct.get('financialProductType'));
            gen.writeStringField('ContractScheme', (String) financialProduct.get('ContractScheme'));
            gen.writeStringField('allowedMinimumDeposit', (String) financialProduct.get('allowedMinimumDeposit'));
            gen.writeStringField('allowedMaximumDeposit', (String) financialProduct.get('allowedMaximumDeposit'));
            gen = buildAllowedTermsJSON ((String) financialProduct.get('allowedTerms'), gen);
            gen.writeEndObject();

        return gen;
    }

    @TestVisible
       private static JSONGenerator buildAllowedTermsJSON(String allowedTerms, JSONGenerator gen) {
        gen.writeFieldName('allowedTerms');
        gen.writeStartArray();
            String[] allowedTerm = allowedTerms.Split(';');
            for (String eachallowedTerm : (String[]) allowedTerm ){
                gen.writeNumber(Integer.valueOf(eachallowedTerm));
            }
        gen.writeEndArray();
        return gen;
    }

    @TestVisible
    private static JSONGenerator buildFinanceJSON(Map<String, Object> finance, JSONGenerator gen) {

        gen.writeFieldName('finance');
        gen.writeStartObject();
            gen.writeNumberField('financeAmount', (Decimal) finance.get('financeAmount'));
            gen.writeNumberField('salePrice', (Decimal) finance.get('financeAmount'));
            gen = buildRatesJSON((Map<String, Object>) finance.get('rates'), gen);
            gen = buildNetDepositJSON((Map<String, Object>) finance.get('netDeposit'), gen);
            gen = buildCashFlowsFinanceStructureJSON((List<Map<String, Object>>) finance.get('cashFlows'), gen);
        gen.writeEndObject();

        return gen;
    }
    
    @TestVisible
    private static JSONGenerator buildNetDepositJSON(Map<String, Object> netDeposit, JSONGenerator gen) {

        gen.writeFieldName('netDeposit');
        gen.writeStartObject();
            gen.writeNumberField('downPayment', (Decimal) netDeposit.get('downPayment'));
        gen.writeEndObject();

        return gen;
    }
    
    @TestVisible
    private static JSONGenerator buildCashFlowsFinanceStructureJSON(List<Map<String, Object>> CashFlows, JSONGenerator gen) {

        gen.writeFieldName('cashFlows');
        gen.writeStartArray();
         for (Map<String, Object> CashFlow : CashFlows) {
                gen.writeStartObject();
             if(CashFlow.get('cashFlowType') == 'fee' && CashFlow.get('id') == 'InvoiceFee'){
                 gen.writeStringField('cashFlowType', (String) cashflow.get('cashFlowType'));
                 gen.writeStringField('id', (String) cashFlow.get('id'));
                 gen.writeNumberField('amount',(Decimal) cashFlow.get('amount'));
             }
             else if(CashFlow.get('cashFlowType') == 'fee' && CashFlow.get('id') == 'IssueFee'){
                 gen.writeStringField('cashFlowType', (String) cashflow.get('cashFlowType'));
                 gen.writeStringField('id', (String) cashFlow.get('id'));
                 gen.writeStringField('categoryCode',(String) cashFlow.get('categoryCode'));
                 gen.writeNumberField('amount',(Decimal) cashFlow.get('amount'));
             }
             else if(CashFlow.get('cashFlowType') == 'fee' && CashFlow.get('id') == 'ExtensionFee'){
                 gen.writeStringField('cashFlowType', (String) cashflow.get('cashFlowType'));
                 gen.writeStringField('id', (String) cashFlow.get('id'));
                 gen.writeNumberField('amount',(Decimal) cashFlow.get('amount'));
             }
             else if(CashFlow.get('cashFlowType') == 'fee' && CashFlow.get('id') == 'IssueFeePercentDLL'){
                 gen.writeStringField('cashFlowType', (String) cashflow.get('cashFlowType'));
                 gen.writeStringField('id', (String) cashFlow.get('id'));
                 gen.writeNumberField('amount', (Decimal) cashFlow.get('amount') != null ? (Decimal) cashFlow.get('amount') : NULL);
             }
             else if(CashFlow.get('cashFlowType') == 'maintenance'){
                 gen.writeStringField('cashFlowType', (String) cashflow.get('cashFlowType'));
                 gen.writeStringField('id', (String) cashFlow.get('id'));
                 gen.writeNumberField('amount',(Decimal) cashFlow.get('amount'));
                 gen.writeStringField('categoryName', (String) cashFlow.get('categoryName'));
             }
             gen.writeEndObject();  
            }
        gen.writeEndArray();

        return gen;
    }

    @TestVisible
    private static JSONGenerator buildRatesJSON(Map<String, Object> rates, JSONGenerator gen) {

        gen.writeFieldName('rates');
        gen.writeStartObject();
            gen.writeNumberField('nominalRate', rates.get('nominalRate') != null ? (Decimal) rates.get('nominalRate') : 0);
            gen.writeNumberField('cof', rates.get('cof') != null ? (Decimal) rates.get('cof') : 0);
            gen.writeNumberField('margin', rates.get('margin') != null ? (Decimal) rates.get('margin') : 0);
        gen.writeEndObject();

        return gen;
    }

    
    @TestVisible
    private static JSONGenerator buildAssetsJSON(List<Map<String, Object>> assets, JSONGenerator gen) {

        gen.writeFieldName('assets');
        gen.writeStartArray();
            for (Map<String, Object> asset : (List<Map<String, Object>>) assets) {
                gen.writeStartObject();
                gen = buildModelIdentifierJSON((Map<String, Object>) asset.get('modelIdentifier'), gen);
                if(!((Map<String, Object>) asset.get('location')).isEmpty()){
                    gen = buildAssetAddressJSON((Map<String, Object>) asset.get('location') , gen);
                }
                gen= buildAssetIdentificationJSON((Map<String, Object>) asset.get('identification'),gen);
                gen.writeNumberField('salePrice', (Decimal) asset.get('salePrice'));
                gen = buildFinanceInfo((Map<String, Object>) asset.get('financeInfo'), gen);
                gen.writeEndObject();
            }
        gen.writeEndArray();

        return gen;
    }

     @TestVisible
    private static JSONGenerator buildAssetAddressJSON(Map<String, Object> location, JSONGenerator gen) {

        gen.writeFieldName('location');
        gen.writeStartObject();
            gen.writeStringField('street', (String) location.get('street'));
            gen.writeStringField('city', (String) location.get('city'));
            gen.writeStringField('postalCode', (String) location.get('postalCode'));
        gen.writeEndObject();

        return gen;
    }
    
    @TestVisible
    private static JSONGenerator buildModelIdentifierJSON(Map<String, Object> modelIdentifier, JSONGenerator gen) {

        gen.writeFieldName('modelIdentifier');
        gen.writeStartObject();
            gen.writeStringField('assetTypeName', (String) modelIdentifier.get('assetTypeName'));
            gen.writeStringField('description', (String) modelIdentifier.get('description') != null ? (String) modelIdentifier.get('description')  : '');
            gen.writeNumberField('quantity', (Integer) modelIdentifier.get('quantity'));
            gen.writeStringField('categoryId', (String) modelIdentifier.get('categoryId'));
        gen.writeEndObject();

        return gen;
    }
    
     @TestVisible
    private static JSONGenerator buildAssetIdentificationJSON(Map<String, Object> identification, JSONGenerator gen) {

        gen.writeFieldName('identification');
        gen.writeStartArray();
        gen.writeStartObject();
            gen = buildIdentifierJSON((Map<String, Object>) identification.get('identifier'), gen);
        gen.writeEndObject();  
        gen.writeEndArray();
  
        return gen;
    }
    @TestVisible
    private static JSONGenerator buildIdentifierJSON(Map<String, Object> identifier, JSONGenerator gen) {

        gen.writeFieldName('identifier');
        gen.writeStartObject();
            gen.writeStringField('type', (String) identifier.get('type'));
        gen.writeEndObject();  

        return gen;
    }

    @TestVisible
    private static JSONGenerator buildFinanceInfo(Map<String, Object> financeInfo, JSONGenerator gen) {

        gen.writeFieldName('financeInfo');
        gen.writeStartObject();
            gen.writeNumberField('financedAmount', (Decimal) financeInfo.get('financedAmount'));
            gen = buildResidualJSON((Map<String, Object>) financeInfo.get('Residual'), gen);
            gen = buildCashFlowsJSON((List<Map<String, Object>>) financeInfo.get('cashFlows'), gen);
        gen.writeEndObject();

        return gen;
    }
    @TestVisible
     private static JSONGenerator buildResidualJSON(Map<String, Object> Residual, JSONGenerator gen) {
        
       gen.writeFieldName('residual');
        gen.writeStartObject();
            gen.writeNumberField('rate', (Decimal) Residual.get('rate'));
            gen.writeNumberField('amount', (Decimal) Residual.get('amount'));
            gen.writeStringField('guarantorName', (String) Residual.get('guarantorName'));
            gen.writeStringField('guarantorOrganizationNumber', (String) Residual.get('guarantorOrganizationNumber'));
            gen.writeStringField('guarantorFinalNumber', (String) Residual.get('guarantorFinalNumber'));
        gen.writeEndObject();

        return gen;
    }
    
    @TestVisible
    private static JSONGenerator buildCashFlowsJSON(List<Map<String, Object>> CashFlows, JSONGenerator gen) {

        gen.writeFieldName('cashFlows');
        gen.writeStartArray();
         for (Map<String, Object> CashFlow : CashFlows) {
                gen.writeStartObject();
                if(CashFlow.get('id') == 'InsuranceCode'){
                    gen.writeStringField('cashFlowType', (String) cashflow.get('cashFlowType'));
                    gen.writeStringField('id', (String) cashflow.get('id'));
                    gen.writeStringField('categoryCode', (String) cashflow.get('categoryCode'));
                }

             else if(CashFlow.get('id') == 'InsuranceRate'){
                 gen.writeStringField('cashFlowType', (String) cashflow.get('cashFlowType'));
                 gen.writeStringField('id', (String) cashflow.get('id'));
                 gen.writeNumberField('categoryCode', (Decimal) cashflow.get('categoryCode'));
             }

             else if(CashFlow.get('id') == 'ItadType'){
                 gen.writeStringField('cashFlowType', (String) cashflow.get('cashFlowType'));
                 gen.writeStringField('id', (String) cashFlow.get('id'));
                 gen.writeStringField('categoryCode',(String) cashFlow.get('categoryCode'));
             }

             else if(CashFlow.get('id') == 'ItadFee'){
                 gen.writeStringField('cashFlowType', (String) cashflow.get('cashFlowType'));
                 gen.writeStringField('id', (String) cashFlow.get('id'));
                 gen.writeNumberField('amount',(Decimal) cashFlow.get('amount'));
             }
             
             else if(CashFlow.get('id') == 'RentalAmount'){
                 gen.writeStringField('cashFlowType', (String) cashflow.get('cashFlowType'));
                 gen.writeStringField('id', (String) cashFlow.get('id'));
                 gen.writeNumberField('amount',(Decimal) cashFlow.get('amount'));
             }

             gen.writeEndObject();  
            }
        gen.writeEndArray();

        return gen;
    }
    
    @TestVisible
    private static JSONGenerator buildadditionalAccountSettingsJSON(List<Map<String, Object>> additionalAccountSettings, JSONGenerator gen) {
        
            gen.writeFieldName('additionalAccountSettings');
            gen.writeStartArray();
                for (Map<String, Object> additionalAccountSetting : (List<Map<String, Object>>) additionalAccountSettings) {
                    gen.writeStartObject();
                      gen.writeStringField('Key', (String) additionalAccountSetting.get('Key'));
                      gen.writeStringField('Value', (String) additionalAccountSetting.get('Value'));
                    gen.writeEndObject();
                }
            gen.writeEndArray();
            return gen;
    }
    
    @TestVisible
    private static JSONGenerator buildFinanceInfoo(Map<String, Object> financeInfo, JSONGenerator gen) {

        gen.writeFieldName('financeInfo');
        gen.writeStartObject();
        if(financeInfo.get('cashFlows') != Null){
            gen = buildCashFlowsJSON((List<Map<String, Object>>) financeInfo.get('cashFlows'), gen);
        }
        gen.writeEndObject();
   
        return gen;
    }
    
    @TestVisible
    private static JSONGenerator buildsoftcostJSON(List<Map<String, Object>> softcosts, JSONGenerator gen) {

        gen.writeFieldName('softcosts');
        gen.writeStartArray();
            for (Map<String, Object> softcost : (List<Map<String, Object>>) softcosts) {
                gen.writeStartObject();
                  gen.writeNumberField('salePrice', (Decimal) softcost.get('salePrice'));
                  gen = buildFinanceInfoo((Map<String, Object>) softcost.get('financeInfo'), gen);
                  gen.writeStringField('typename', (String) softcost.get('typename'));
                  gen.writeStringField('categoryid', (String) softcost.get('categoryid'));
                  gen.writeNumberField('quantity', (Decimal) softcost.get('quantity'));
                gen.writeEndObject();
            }
        gen.writeEndArray();
        return gen;
    }
    
    @TestVisible
    private static JSONGenerator buildcontractConditionsJSON(Map<String, Object> contractConditions, JSONGenerator gen) {
        
            gen.writeFieldName('contractConditions');
            gen.writeStartObject();
                if(contractConditions.get('specialConditions') != null){
                    gen = buildSpecialConditionsInfo((List<Map<String, Object>>) contractConditions.get('specialConditions'), gen);
                }
                gen.writeStringField('generalConditionRef', (String) contractConditions.get('generalConditionRef'));
            gen.writeEndObject();
            return gen;
    }
    
    @TestVisible
    private static JSONGenerator buildSpecialConditionsInfo(List<Map<String, Object>> specialConditions, JSONGenerator gen) {
            
            gen.writeFieldName('specialConditions');
            gen.writeStartArray();
                for (Map<String, Object> specialCondition : (List<Map<String, Object>>) specialConditions) {
                    gen.writeStartObject();
                      gen.writeStringField('condition', (String) specialCondition.get('condition'));
                      gen.writeStringField('conditionValue', (String) specialCondition.get('conditionValue'));
                    gen.writeEndObject();
                }
            gen.writeEndArray();
            return gen;
    }
        
}