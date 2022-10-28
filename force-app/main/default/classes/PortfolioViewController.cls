/*********************************************************************************************************
* Portfolio View Controller 
*
* change log:
* 10-18-2021 - Mark Moser Created class
* 01-18-2022 - Mark Moser replace stomped on code
* 01-31-2022 - Geetha added fields for Download Portfolio - at asset level
* 04-28-2022 - Geetha modified Download Portfolio logic - Ability to filter records based on criteria:PBI655489
* 05-31-2022 - Geetha fixed bugs 781997, 770128, 781978, 796918 
* 08-11-2022 - Fernando Nereu de Souza PBI 829854 - Filter Contracts such that Contract > Program > Program name DOES NOT Contain 'gfc'
**********************************************************************************************************/
public with sharing class PortfolioViewController {
/*********************************************************************************************************
* wrapContract
*
**********************************************************************************************************/
    
    public class wrapContract {
        public Contract__c contract {get; set;}
        public String serial {get; set;}
        public String make {get; set;}
        
        public wrapContract( Contract__c c, String serial, String make){
            this.contract = c;
            this.serial = serial;
            this.make = make;
        }
        
    }
    
    static final Map<String, String> fieldMapping = new Map<String, String> {
        'contractNumber' => 'Name',
            'customerName' => 'End_User__r.Name',
            //'salesRep' => 'test',
            'financeType' => 'Purchase_Option__c',
            //'serials' => 'test',
            //'makes' => 'test',
            'term' => 'Contract_Term_months__c',
            'remainPay' => 'Payments_Remaining__c',
            'health' => 'Delinquency_Status__c',
            'status' =>'Status_Text__c'
            };
                
                /*********************************************************************************************************
* getTotalRecords
*
**********************************************************************************************************/
                
                @AuraEnabled
                public static Integer getTotalRecords() {
                    
                    
                    Integer count = 0;
                    
                    AggregateResult[] ARs =
                        [select count(id) myCount
                         from
                         Contract__c
                        ];
                    
                    for (AggregateResult ar : ARs) {
                        count = (Integer)ar.get('myCount');
                    }
                    
                    return count;
                    
                    
                    
                }
    
    /*********************************************************************************************************
* getRecords
*
**********************************************************************************************************/
    
    @AuraEnabled
    public static String getRecords(Integer offSetCount, String months, String status, String orderByField, String orderByDirection, String filter) {
        
        String startDate, endDate;
        String whereClause = '';
        String nullSeq = '';
        system.debug('offSetCount = '  +offSetCount);
        if(String.isNotBlank(orderByDirection)) {
            system.debug('orderbydir = ' +orderByDirection);
            system.debug('orderByField = ' +orderByField);
            if(orderByDirection == 'asc') {
                nullSeq = 'first';
            }
            else{
                nullSeq = 'last';
            }
            
            if(orderByField == 'endUserURL') {
                orderByField = 'customerName';
            }else if(orderByField == 'contractUrl') {
                orderByField = 'contractNumber';
            }
            system.debug('orderByField = ' +orderByField);
        }
        
        
        if (months.isNumeric()) {
            startDate = months == null || months == '0' ? DateTime.newInstance(Date.valueOf('2000-01-01'), Time.newInstance(0, 0, 0, 0)).format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'') : DateTime.newInstance(Date.valueOf(months+'-01-01'), Time.newInstance(0, 0, 0, 0)).format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');
            endDate = months == null || months == '0' ?DateTime.newInstance(Date.valueOf('2200-02-01'), Time.newInstance(0, 0, 0, 0)).format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'') : DateTime.newInstance(Date.valueOf(months+'-12-31'), Time.newInstance(0, 0, 0, 0)).format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');
            whereClause = 'WHERE CreatedDate >= ' + startDate + ' AND CreatedDate <= ' + endDate;
        } else {
            whereClause = 'WHERE CreatedDate = ' + months;
        }
        
        String parsedStatus = status == 'ALL' ? '' : status;
        whereClause = whereClause == '' ? 'WHERE status_text__c LIKE \'%' + String.escapeSingleQuotes(parsedStatus) + '%\'' : whereClause + ' AND status_text__c LIKE \'%' + String.escapeSingleQuotes(parsedStatus) + '%\'';
        
        if (filter != null) {
            
            whereClause +=  ' AND ( ';
            whereClause += ' purchase_option__c like ' + '\'' + '%' + filter + '%' + '\'';
            whereClause += ' or End_User__r.name like ' + '\''  + '%' + filter + '%'+ '\'';
            
            try{
                Integer x = Integer.valueOf(filter);
                whereClause += ' or Payments_Remaining__c = ' +  filter;
            }
            catch (exception e) {
                //its not an integer don't try
            }
            
            try{
                Integer x = Integer.valueOf(filter);
                whereClause += ' or Contract_term_months__c = ' +  filter;
            }
            catch (exception e) {
                //its not an integer don't try
            }
            
            whereClause += ' or Delinquency_Status__c like ' + '\''  + '%' + filter + '%'+ '\'';
            whereClause += ' or Name like ' + '\''  + '%' + filter + '%' + '\'';
            
            
            
            String searchStr=  '%' + filter + '%';
            List<Asset__c> assetList = [select Asset_Serial_Number__c
                                        , Asset_Brand_Make__c
                                        , Contract__c
                                        from Asset__c
                                        where asset_Serial_Number__c like : searchStr
                                        or Asset_Brand_Make__c like : searchStr
                                        limit 2000
                                       ];
            
            Set<ID> cSet = new Set<ID>();
            for (Asset__c a:assetList)
                cSet.add(a.contract__c);
            
            if (!cSet.isEmpty()) {
                whereClause += ' or id in' + '(';
                Integer j=0;
                for (ID cId:cSet) {
                    if (j < cSet.size() && j > 0)
                        whereClause += ' , ';
                    whereClause += '\'' + cId + '\'';
                    j++;
                }
                whereClause +=  ' ) ';
                
            }
            whereClause +=  ' ) ';
        }
        
        //Start: PBI - 829854 - Author: Fernando Nereu de Souza
        if(String.isNotBlank(whereClause)){
            whereClause += ' AND (NOT Program__r.Name LIKE \'%gfc%\')';
        }
        else{
            whereClause += 'Where (NOT Program__r.Name LIKE \'%gfc%\')';
        }
        //End: PBI - 829854 - Author: Fernando Nereu de Souza
        
        List<wrapContract> wrapList = new List<wrapContract>();
        
        List<Contract__c> cList = new List<Contract__c>();
        
        //Creating query
        String query = 'SELECT Id , Name, End_User__r.name, End_User__c, Sales_Rep_Name__c, Opportunity__r.Partner_Sales_Rep__r.Name, Purchase_Option__c, Contract_Term_months__c, Payments_Remaining__c, Health__c, Delinquency_Status__c, Status_text__c FROM Contract__c '
            + whereClause;
        String orderclause = String.isBlank(orderByField) ? '' : ' ORDER BY ' + fieldMapping.get(orderByField)+ ' ' + orderByDirection + ' NULLS ' + nullSeq;
        query = orderclause == '' ? query : query + orderclause;
        query = query + ' LIMIT 20 OFFSET ' + offSetCount;
        system.debug('query is: ' + query);
        cList = Database.query(query);
        
        /*cList = [select id
,name
,End_User__r.name
,Sales_Rep_Name__c
,Purchase_Option__c
,Contract_Term_months__c
,Payments_Remaining__c
,Health__c
,Delinquency_Status__c
,Status_text__c
from
Contract__c
where createdDate >= :startDate and createdDate <= :endDate
//and sales_rep_name__c like :salesrep
and status_text__c like :searchStatus
order by Payments_Remaining__c
limit 20
offset : offSetCount
];*/
        
        Set<ID> contractSet = new Set<ID>();
        for(Contract__c c:cLIst) {
            contractSet.add(c.id);
        }
        
        Map<ID,String> serialMap = new Map<ID,String>();
        Map<ID,String> makeMap = new Map<ID,String>();
        
        List<Asset__c> assetList = [select Asset_Serial_Number__c
                                    , Asset_Brand_Make__c
                                    , Contract__c
                                    from Asset__c
                                    where Contract__c in : contractSet
                                    ORDER BY Asset_Serial_Number__c ASC
                                    
                                   ];
        
        Integer i=0;
        Set<ID> contractDoneSet = new Set<ID>();
        
        Map<ID,Integer> countSet = new Map<ID,Integer>();
        
        
        for (Asset__c a:assetList) {  //only string 2 assets together
            
            if (countSet.containsKey(a.Contract__c)) {
                Integer c = countSet.get(a.Contract__c);
                c++;
                countSet.put(a.Contract__c,c);
            }
            else {
                countSet.put(a.Contract__c,1);
            }
            
            
            String s = '';
            if (serialMap.containsKey(a.Contract__c)) {
                s = serialMap.get(a.Contract__c);
                s = s + ';' + a.Asset_Serial_Number__c;
            }
            else{
                s = a.Asset_Serial_Number__c;
            }
            
            if(countSet.get(a.Contract__c) != null)
                if(countSet.get(a.Contract__c) < 3)
                serialMap.put(a.Contract__c,s);
            
            
            s = '';
            if (makeMap.containsKey(a.Contract__c)) {
                s = makeMap.get(a.Contract__c);
                s = s + ';' + a.Asset_Brand_Make__c;
            }
            else{
                s = a.Asset_Brand_Make__c;
            }
            if(countSet.get(a.Contract__c) != null)
                if(countSet.get(a.Contract__c) < 3)
                makeMap.put(a.Contract__c,s);
            
            
        }
        
        for (Contract__c c:cList) {
            wrapList.add(new wrapContract(c,serialMap.get(c.id), makeMap.get(c.id)));
        }
        return JSON.serialize(wrapList);
        
    }
    
    //Wrapper class to set the values for Download Portfolio functionality
    public class wrapperClass {
        @AuraEnabled public string customerLegalName {get; set;}
        @AuraEnabled public string contractNumber {get; set;}
        @AuraEnabled public string assetID {get; set;}
        @AuraEnabled public string contId {get; set;}
        @AuraEnabled public string assetNumber {get; set;}
        @AuraEnabled public Decimal assetOriginalCost {get; set;}
        @AuraEnabled public Decimal assetEquipmentPayment {get; set;}
        @AuraEnabled public Decimal contractOriginalCost {get; set;}
        @AuraEnabled public Decimal totalEquipmentPayment {get; set;}
        @AuraEnabled public Decimal servicePayment {get; set;}
        @AuraEnabled public String assetBrand {get; set;}
        @AuraEnabled public String assetModel {get; set;}
        @AuraEnabled public String assetSerialNumber {get; set;}
        @AuraEnabled public String assetDescription {get; set;}
        @AuraEnabled public String assetStatus {get;set;}
        @AuraEnabled public Date contractStartDate {get; set;}
        @AuraEnabled public Decimal contractTerm {get; set;}
        @AuraEnabled public Date contractMaturityDate {get; set;}
        @AuraEnabled public Decimal numofPaymentRemaining {get; set;}
        @AuraEnabled public String conPurchaseOpt {get; set;}
        @AuraEnabled public String conPaymentfreq {get; set;}
        @AuraEnabled public String conType {get; set;}
        @AuraEnabled public String conSignerName {get; set;}
        @AuraEnabled public Decimal daysPastdue {get; set;}
        @AuraEnabled public Date lastpayRcdDate {get; set;}
        @AuraEnabled public String custAccNum {get; set;}
        @AuraEnabled public String custAddressline1 {get; set;}
        @AuraEnabled public string custAddressline2 {get; set;}
        @AuraEnabled public String custCity {get; set;}
        @AuraEnabled public string custState {get; set;}
        @AuraEnabled public string custPostalcode {get; set;}
        @AuraEnabled public string custPhnum {get; set;}
        @AuraEnabled public String astAddress1 {get; set;}
        @AuraEnabled public String astAddress2 {get; set;}
        @AuraEnabled public String astCity {get; set;}
        @AuraEnabled public String astState {get; set;}
        @AuraEnabled public String astPostalCode {get; set;}
        @AuraEnabled public String astBillingAdd1 {get; set;}
        @AuraEnabled public String astBillingAdd2 {get; set;}
        @AuraEnabled public String astBillingCity {get; set;}
        @AuraEnabled public String astBillingState {get; set;}
        @AuraEnabled public String astBillingPstCode {get; set;}
        @AuraEnabled public String billingAddress {get; set;}
        @AuraEnabled public string billingCity {get; set;}
        @AuraEnabled public string billingState {get; set;}
        @AuraEnabled public string billingPostalCode {get; set;}
        @AuraEnabled public string salesRep {get; set;}
    }
    
    //Method for Download Portfolio (Called in LWC:PortfolioView)
    @AuraEnabled
    public static List<wrapperClass> getdownloadRecords(String months, String status,String filter){
        /*new code start*/
        
        String startDate, endDate;
        String whereClause = '';
        String nullSeq = '';
        
        if (months.isNumeric()) {
            startDate = months == null || months == '0' ? DateTime.newInstance(Date.valueOf('2000-01-01'), Time.newInstance(0, 0, 0, 0)).format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'') : DateTime.newInstance(Date.valueOf(months+'-01-01'), Time.newInstance(0, 0, 0, 0)).format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');
            endDate = months == null || months == '0' ?DateTime.newInstance(Date.valueOf('2200-02-01'), Time.newInstance(0, 0, 0, 0)).format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'') : DateTime.newInstance(Date.valueOf(months+'-12-31'), Time.newInstance(0, 0, 0, 0)).format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');
            whereClause = 'WHERE contract__r.CreatedDate >= ' + startDate + ' AND contract__r.CreatedDate <= ' + endDate;
        } else {
            whereClause = 'WHERE contract__r.CreatedDate = ' + months;
        }
        
        String parsedStatus = status == 'ALL' ? '' : status;
        whereClause = whereClause == '' ? 'WHERE contract__r.status_text__c LIKE \'%' + String.escapeSingleQuotes(parsedStatus) + '%\'' : whereClause + ' AND contract__r.status_text__c LIKE \'%' + String.escapeSingleQuotes(parsedStatus) + '%\'';
        
        if (filter != null) {
            
            whereClause +=  ' AND ( ';
            whereClause += ' contract__r.purchase_option__c like ' + '\'' + '%' + filter + '%' + '\'';
            whereClause += ' or contract__r.End_User__r.name like ' + '\''  + '%' + filter + '%'+ '\'';
            
            try{
                Integer x = Integer.valueOf(filter);
                whereClause += ' or contract__r.Payments_Remaining__c = ' +  filter;
            }
            catch (exception e) {
                //its not an integer don't try
            }
            
            try{
                Integer x = Integer.valueOf(filter);
                whereClause += ' or contract__r.Contract_term_months__c = ' +  filter;
            }
            catch (exception e) {
                //its not an integer don't try
            }
            
            whereClause += ' or contract__r.Delinquency_Status__c like ' + '\''  + '%' + filter + '%'+ '\'';
            whereClause += ' or contract__r.Name like ' + '\''  + '%' + filter + '%' + '\'';
            
            String searchStr=  '%' + filter + '%';
            List<Asset__c> assetList = [select Asset_Serial_Number__c
                                        , Asset_Brand_Make__c
                                        , Contract__c
                                        from Asset__c
                                        where asset_Serial_Number__c like : searchStr
                                        or Asset_Brand_Make__c like : searchStr
                                        limit 2000
                                       ];
            
            Set<ID> cSet = new Set<ID>();
            for (Asset__c a:assetList)
                cSet.add(a.contract__c);
            
            if (!cSet.isEmpty()) {
                whereClause += ' or contract__c in' + '(';
                Integer j=0;
                for (ID cId:cSet) {
                    if (j < cSet.size() && j > 0)
                        whereClause += ' , ';
                    whereClause += '\'' + cId + '\'';
                    j++;
                }
                whereClause +=  ' ) ';
                
            }
            whereClause +=  ' ) ';
        }
        /*new code end*/
        
        if(String.isNotBlank(whereClause)){
            whereClause += ' AND (NOT Contract__r.Program__r.Name LIKE \'%gfc%\')';
        }
        else{
            whereClause += 'Where (NOT Contract__r.Program__r.Name LIKE \'%gfc%\')';
        }
        //End: PBI - 829854 - Author: Fernando Nereu de Souza

        
        List<wrapperClass> wrapList = new List<wrapperClass>();
        List<Asset__c> assetList = new List<Asset__c>();
        String conQuery = 'select contract__r.end_user__r.System_Name__c,'+
            'contract__r.Name,'+
            'contract__r.Id,'+
            'Name,'+
            'Id,'+
            'Asset_Original_Cost__c,'+
            'Asset_Equipment_Rent_Payment__c,'+
            'contract__r.Booked_Amount__c,'+
            'contract__r.Payment_Amount__c,'+
            'contract__r.Service_Payment__c,'+
            'Asset_Brand_Make__c,'+
            'Asset_Model__c,'+
            'Asset_Serial_Number__c,'+
            'Asset_Description__c,'+
            'Asset_Status__c,'+
            'contract__r.Contract_Start_Date__c,'+
            'contract__r.Contract_Term_months__c,'+
            'contract__r.Maturity_Date__c,'+
            'contract__r.Payments_Remaining__c,'+
            'contract__r.Purchase_Option__c,'+
            'contract__r.Payment_Frequency__c,'+
            'contract__r.Contract_Type__c,'+
            'contract__r.Signer__c,'+
            'contract__r.Number_of_Days_Past_Due__c,'+
            'contract__r.Last_Payment_Received_Date__c,'+
            'contract__r.end_user__r.AccountNumber,'+
            'contract__r.end_user__r.BillingStreet,'+
            'contract__r.end_user__r.BillingCity,'+
            'contract__r.end_user__r.BillingState,'+
            'contract__r.end_user__r.BillingPostalCode,'+
            'contract__r.end_user__r.Phone,'+
            'Asset_Install_Address_Line_1__c,'+
            'Asset_Install_Address_Line_2__c,'+
            'Asset_City_Install_Address__c,'+
            'Asset_State_Install_Address__c,'+
            'Asset_Postal_Code_Install_Address__c,'+
            'Asset_Billing_Address_Line_1__c,'+
            'Asset_Billing_Address_Line_2__c,'+
            'Asset_Billing_City__c,'+
            'Asset_Billing_State__c,'+
            'Asset_Billing_Postal_Code__c,'+
            'contract__r.account__r.BillingAddress,'+
            'contract__r.account__r.BillingCity,'+
            'contract__r.account__r.BillingState,'+
            'contract__r.account__r.BillingPostalCode,'+
            'contract__r.Sales_Rep_Name__c '+
            'from Asset__c ' ;
        String limitsize = ' limit 40000 ';
        conQuery = conQuery + whereClause + limitsize;
        system.debug('conQuery' +conQuery);
        assetList = Database.query(conQuery);
        
        if(assetList.size()>0) {
            for(Asset__c ast :assetList) {
                wrapperClass wc = new wrapperClass();
                wc.customerLegalName = ast.contract__r.end_user__r.System_Name__c;
                wc.contId = ast.contract__r.id;
                wc.contractNumber = ast.contract__r.Name;
                wc.assetID = ast.id;
                wc.assetNumber = ast.Name;
                wc.assetOriginalCost =ast.Asset_Original_Cost__c;
                wc.assetEquipmentPayment = ast.Asset_Equipment_Rent_Payment__c;
                wc.contractOriginalCost = ast.Contract__r.Booked_Amount__c;
                wc.totalEquipmentPayment = ast.contract__r.Payment_Amount__c;
                wc.servicePayment = ast.contract__r.Service_Payment__c;
                wc.assetBrand = ast.Asset_Brand_Make__c;
                wc.assetModel = ast.Asset_Model__c;
                wc.assetSerialNumber = ast.Asset_Serial_Number__c;
                wc.assetDescription = ast.Asset_Description__c;
                wc.assetStatus = ast.Asset_Status__c;
                wc.contractStartDate = ast.contract__r.Contract_Start_Date__c;
                wc.contractTerm = ast.contract__r.Contract_Term_months__c;
                wc.contractMaturityDate = ast.contract__r.Maturity_Date__c;
                wc.numofPaymentRemaining = ast.contract__r.Payments_Remaining__c;
				wc.conPurchaseOpt =ast.contract__r.Purchase_Option__c;
                wc.conPaymentfreq = ast.contract__r.Payment_Frequency__c;
                wc.conType = ast.contract__r.Contract_Type__c;
                wc.conSignerName = ast.contract__r.Signer__c;
                wc.daysPastdue = ast.contract__r.Number_of_Days_Past_Due__c;
                wc.lastpayRcdDate = ast.contract__r.Last_Payment_Received_Date__c;
                wc.custAccNum =  ast.contract__r.end_user__r.AccountNumber;
                wc.custAddressline1 = ast.contract__r.end_user__r.BillingStreet;
                wc.custCity = ast.contract__r.end_user__r.BillingCity;
                wc.custState = ast.contract__r.end_user__r.BillingState;
                wc.custPostalcode = ast.contract__r.end_user__r.BillingPostalCode;
                wc.custPhnum = ast.contract__r.end_user__r.Phone;
                wc.astAddress1 = ast.Asset_Install_Address_Line_1__c;
                wc.astAddress2 = ast.Asset_Install_Address_Line_2__c;
                wc.astCity = ast.Asset_City_Install_Address__c;
                wc.astState =ast.Asset_State_Install_Address__c;
                wc.astPostalCode = ast.Asset_Postal_Code_Install_Address__c;
                wc.astBillingAdd1 = ast.Asset_Billing_Address_Line_1__c;
                wc.astBillingAdd2 = ast.Asset_Billing_Address_Line_2__c;
                wc.astBillingCity = ast.Asset_Billing_City__c;
                wc.astBillingState = ast.Asset_Billing_State__c;
                wc.astBillingPstCode = ast.Asset_Billing_Postal_Code__c;
                //wc.billingAddress = ast.contract__r.account__r.BillingAddress;
                wc.billingCity = ast.contract__r.account__r.BillingCity;
                wc.billingState = ast.contract__r.account__r.BillingState;
                wc.billingPostalCode = ast.contract__r.account__r.BillingPostalCode;
                wc.salesRep = ast.contract__r.Sales_Rep_Name__c;

                wrapList.add(wc);
            }
        }
        return wrapList;
    }
    
}