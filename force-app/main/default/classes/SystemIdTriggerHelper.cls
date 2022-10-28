//PBI:529195:As a sales rep, I need the entity ID stamped on End User Accounts.
public with sharing class SystemIdTriggerHelper{ 
    public static Map<String, String> dealerStatusMap = new Map<String, String>{
            'Active' => 'Active',
            'Inactive' => 'Inactive',
            'ACTIVE' => 'Active',
            'INACTIVE' => 'Inactive',
            'TERMINATED' => 'Terminated',    
            'One Off' => 'Active',
            'Cutt Off' => 'Inactive',
            'Avoid' => 'Inactive',
            'Caution' => 'Active',
            'Out of Business' => 'Inactive',
            '1'  => 'Active',
            '2' => 'Active',
            '3' => 'Inactive',
            '4' => 'Inactive',
            '5' => 'Terminated'
    };

    public static void helpBeforeInsert(List<System_ID__c> newSysIds){
        setInitialValues(newSysIds);
        setCurrency(newSysIds);
        //PBI608648:If the SystemID contains AccountID ->
        //then no need to create a new Account instead update the Account with all the systemID values (used to create/update).
        accountProcess(newSysIds);
    }

    public static void helpBeforeUpdate(Map<Id, System_ID__c> oldSysIdMap, Map<Id, System_ID__c> newSysIdMap){
        setCurrency(newSysIdMap.values());
        updateAccount(newSysIdMap.values());
    }

    public static void setInitialValues(List<System_ID__c> sysIds){
        for(System_ID__c sysId : sysIds){
            if(String.isBlank(sysId.Source_System__c)){
                sysId.Source_System__c = 'GDW_Wayne';
                sysId.Location__c = 'United States';
                if(String.isNotBlank(sysId.UNQ_Vendor__c)){
                    sysId.System_ID__c = sysId.UNQ_Vendor__c;
                }else{
                    sysId.System_ID__c = sysId.UNQ_Customer__c;
                }
            }
            if(String.isBlank(sysId.Type__c)){
                if(String.isNotBlank(sysId.UNQ_Vendor__c)){
                    sysId.Type__c = 'Vendor';
                }else{
                    sysId.Type__c = 'End User';
                }
            }
        }
    }

    public static void setCurrency(List<System_ID__c> sysIds){
        for(System_ID__c sysId : sysIds){
            if(sysId.Country__c == 'United States' || sysId.Country__c == 'US'){
                sysId.CurrencyIsoCode = 'USD';
            }else if(sysId.Country__c == 'Canada' || sysId.Country__c == 'CA'){
                sysId.CurrencyIsoCode = 'CAD';
            }else{
                sysId.CurrencyIsoCode = 'EUR';
            }
        }
    }
    
    public static void accountProcess(List<System_ID__c> sysIds){
        List<System_ID__c> updateAccountSysIds = new List<System_ID__c>();
        List<System_ID__c> matchAccountSysIds = new List<System_ID__c>();
        for(System_ID__c sysId : sysIds){
            if(String.isNotBlank(sysId.Account__c)){
                updateAccountSysIds.add(sysId);
            }else{
                matchAccountSysIds.add(sysId);
            }
        }
        
        if(updateAccountSysIds.size()>0){
            updateAccount(updateAccountSysIds);
        }
        if(matchAccountSysIds.size()>0){
            matchSysIds(matchAccountSysIds);
        } 
    }

    public static void matchSysIds(List<System_ID__c> sysIds) {
        //Matching fields
        Set<String> phones = new Set<String>();
        Set<String> streets = new Set<String>();
        Set<String> cities = new Set<String>();
        Set<String> states = new Set<String>();
        Set<String> countries = new Set<String>();
        Set<String> legalNames = new Set<String>();
        Set<String> zipPostalCodes = new Set<String>();

        //Listed used to separate the cass of incoming end user system Ids, one for vendors the other for customers
        List<System_ID__c> validVendorSysIds = new List<System_ID__c>();
        List<System_ID__c> otherSysIds = new List<System_ID__c>();
        List<System_ID__c> validOtherSysIds = new List<System_ID__c>();
        List<System_ID__c> unmatchedSysIds = new List<System_ID__c>();
        //List of all systemIds that require an update to an account
        List<System_ID__c> accountsToUpdateSys = new List<System_ID__c>();
        //List of the system Ids to delete
        //List<System_ID__c> sysIdsToDelete = new List<System_ID__c>();
        Map<Id, Account> accById = new Map<Id, Account>();

        //NEW LOGIG FOR MATCHING: USING ONLY LEGAL ENTITY IDS plus container for other sys id codes
        List<String> validUNQVendors = new List<String>();
        for (System_ID__c sysId : sysIds) {
            if (String.isNotBlank(sysId.UNQ_Vendor__c)) {
                validUNQVendors.add(sysId.UNQ_Vendor__c);
                validVendorSysIds.add(sysId);
            }else{
                otherSysIds.add(sysId);
            }
        }

        
        //Matching criteria for other sys ids
        
        //Initial set up for all search fields
        if(!otherSysIds.isEmpty()){
            for(System_ID__c sysId : otherSysIds){
                if (String.isNotBlank(sysId.Phone__c)
                        && String.isNotBlank(sysId.Street__c)
                        && String.isNotBlank(sysId.City__c)
                        && String.isNotBlank(sysId.State__c)
                        && String.isNotBlank(sysId.Country__c)
                        && String.isNotBlank(sysId.Legal_Entity_Name__c)
                        && String.isNotBlank(sysId.Zip_Postal_Code__c))
                {
                    phones.add(sysId.Phone__c);
                    streets.add(sysId.Street__c);
                    cities.add(sysId.City__c);
                    states.add(sysId.State__c);
                    countries.add(sysId.Country__c);
                    legalNames.add(sysId.Legal_Entity_Name__c);
                    zipPostalCodes.add(sysId.Zip_Postal_Code__c);
                    validOtherSysIds.add(sysId);
                }else{
                    unmatchedSysIds.add(sysId);
                }
            }
        }
        
        //Query to find the matching system ids
        List<System_ID__c> existingOtherSysIds = [
                SELECT Id, Account__c, System_Name__c, Phone__c, City__c, State__c, Country__c, Street__c,
                        Legal_Entity_Name__c, LastModifiedDate, Zip_Postal_Code__c
                FROM System_ID__c
                WHERE Phone__c IN:phones
                AND Street__c IN:streets
                AND City__c IN:cities
                AND State__c IN:states
                AND Country__c IN:countries
                AND Legal_Entity_Name__c IN:legalNames
                AND Zip_Postal_Code__c IN:zipPostalCodes
                ORDER BY LastModifiedDate DESC
        ];

        //BEGINNING LOGIC FOR END USER CUSTOMERS AND OTHERS
        if(!existingOtherSysIds.isEmpty()){
            Map<String, System_ID__c> existingOtherSysIdByKey = new Map<String, System_ID__c>();

            //Map the possible matches by a key to easily find from the System ID
            for (System_ID__c sysId : existingOtherSysIds) {
                String key = sysId.Phone__c + '-' +
                        sysId.Street__c + '-' +
                        sysId.City__c + '-' +
                        sysId.State__c + '-' +
                        sysId.Country__c + '-' +
                        sysId.Legal_Entity_Name__c + '-' +
                        sysId.Zip_Postal_Code__c;
                existingOtherSysIdByKey.put(key, sysId);
            }

            //Try to find matches
            for (System_ID__c sysId : validOtherSysIds) {
                String key = sysId.Phone__c + '-' +
                        sysId.Street__c + '-' +
                        sysId.City__c + '-' +
                        sysId.State__c + '-' +
                        sysId.Country__c + '-' +
                        sysId.Legal_Entity_Name__c + '-' +
                        sysId.Zip_Postal_Code__c;
                System_ID__c matchedSysId = existingOtherSysIdByKey.get(key);

                //If a match was found and the new System ID doesn't have an Account
                if (matchedSysId != null && matchedSysId.Account__c != null && String.isBlank(sysId.Account__c)) {
                    sysId.Account__c = matchedSysId.Account__c;
                    accountsToUpdateSys.add(sysId);
                }else{
                    unmatchedSysIds.add(sysId);
                }
            }
        }
        else{
            unmatchedSysIds.addAll(validOtherSysIds);
        }

        //END OF LOGIC FOR END USER CUSTOMERS AND OTHERS


        //BEGINNING LOGIC FOR END USER VENDORS
        List<System_ID__c> eVendorSysIds = new List<System_ID__c>();
        List<Id> accIdsToQuery = new List<Id>();
        Map<String, System_ID__c > eVendorSysIdsMap = new Map<String, System_ID__c>();
        Map<Id, Account> accsFromESys = new Map<Id, Account>();

        //Check first to see if there are valide vendor system Ids
        if(!validUNQVendors.isEmpty()){
            eVendorSysIds = [
                    SELECT Id, Account__c, UNQ_Vendor__c
                    FROM System_ID__c
                    WHERE UNQ_Vendor__c IN:validUNQVendors
            ];
        }

        //create a key value map to search for existing system Ids to match with the incoming ones
        if(!eVendorSysIds.isEmpty()){
            for(System_ID__c sysId: eVendorSysIds){
                eVendorSysIdsMap.put(sysId.UNQ_Vendor__c, sysId);
                if(sysId.Account__c != null){
                    accIdsToQuery.add(sysId.Account__c);
                }
            }
        }


        //Query here to get the account entity id details for valid vendor sys ids
        if(!accIdsToQuery.isEmpty()){
            accsFromESys = new Map<Id, Account> ([
                    SELECT Id, ATS_ID_s__c
                    FROM Account
                    WHERE Id IN :accIdsToQuery ]);
        }

        //Matching component for existing sysIds to incoming ones
        if(!validVendorSysIds.isEmpty()){
            //Try to find matches -- New logic for matching in here
            for (System_ID__c sysId : validVendorSysIds) {
                System_ID__c matchedSysId = eVendorSysIdsMap.get(sysId.UNQ_Vendor__c);
                if (matchedSysId != null && matchedSysId.Account__c != null && String.isBlank(sysId.Account__c)) {
                    sysId.Account__c = matchedSysId.Account__c;
                    accountsToUpdateSys.add(sysId);
                }else{
                    unmatchedSysIds.add(sysId);
                }
            }
        }
        //END LOGIC FOR END USER VENDOR

        //Record type key map implementation
        List<RecordType> recTypes = [
                SELECT Name, Id
                FROM RecordType
                WHERE SobjectType = 'Account'
                AND Name IN ('Vendor', 'End User', 'Prospect')
        ];

        Map<String, Id> recTypeByName = new Map<String, Id>();
        for (RecordType rt : recTypes) {
            recTypeByName.put(rt.Name, rt.Id);
        }
        
        //As per discussion with Brent we need to set Record type as vendor if 
        // Sysid.Type is Manufacturer
        if(recTypeByName.containsKey('Vendor')){
            recTypeByName.put('Manufacturer',recTypeByName.get('Vendor'));
        }


        //lOGIC TO UPDATE THE ACCOUNTS
        Map<Id, String> accEntityIdMap = new Map<Id, String>();
        if(!accountsToUpdateSys.isEmpty()){
            for (System_ID__c sysId: accountsToUpdateSys){
                String status = dealerStatusMap.get(sysId.Dealer_Status__c);
                if (status == null) {
                    status = 'Active';
                }
                String entityId;
                
                if(String.isNotBlank(sysId.UNQ_Vendor__c) && String.isNotBlank(sysId.System_ID__c)){ 
                    if(sysId.Location__c =='Canada'){
                      entityId = sysId.System_ID__c.substring(0,6) + '.' + sysId.System_ID__c.substring(6,sysId.System_ID__c.length());
                    }else{
                        entityId = sysId.System_ID__c;
                    }
                }

                Account currAcc = accsFromESys.get(sysId.Account__c);
                if(currAcc != null){
                    String currEntityId;
                    if(accEntityIdMap.containsKey(currAcc.Id)){
                        currEntityId = accEntityIdMap.get(currAcc.Id);
                    }else{
                        currEntityId = currAcc.ATS_ID_s__c;
                    }
                    if(String.isNotBlank(entityId) && String.isNotBlank(currEntityId)){
                        if(!checkForDuplicateEntityId(currEntityId.split(';'), entityId) && (currEntityId.length() + entityId.length() < 255)){
                            entityId = entityId + ';' + currEntityId;
                        }else{
                            entityId = currEntityId;
                        }
                    }
                    if(accEntityIdMap.containsKey(currAcc.Id) || (!accEntityIdMap.containsKey(currAcc.Id) && entityId != null)){
                        accEntityIdMap.put(currAcc.Id, entityId);
                    }
                }
                Id RT = sysId.Type__c == 'End User' || sysId.Type__c == 'Prospect' ? recTypeByName.get(sysId.Type__c) : recTypeByName.get('Vendor');
                //Update the matched Account with values from the new System ID
                if(sysId.Location__c == 'Canada'){
                    
                    accById.put(sysId.Account__c, new Account(
                        Id = sysId.Account__c,
                        System_Name__c = sysId.System_Name__c,
                        BillingStreet = sysId.Street__c,
                        BillingCity = sysId.City__c,
                        BillingState = sysId.State__c,
                        BillingCountry = sysId.Country__c,
                        BillingPostalCode = sysId.Zip_Postal_Code__c,
                        Risk_Rating__c = sysId.Risk_Rating__c,
                        Dealer_Status__c = status,
                        ATS_ID_s__c = sysId.UNQ_Vendor__c==null?sysId.System_ID__c :entityId,
                        RecordTypeId = RT,
                        US__c = (sysId.Location__c == 'United States'),
                        Canada__c = (sysId.Location__c == 'Canada'),
                        CurrencyIsoCode = sysId.CurrencyIsoCode,
                        //New fields as per #378119
                        Contact_Status__c = sysId.Contact_Status__c,
                        Legal_Entity_Description__c = sysId.Legal_Entity_Description__c,
                        Email__c = sysId.Email__c,
                        Fax = sysId.Fax__c,
                        Inventory_Finance_Agreement_Signed_Date__c = sysId.Inventory_Finance_Agreement_Signed_Date__c,
                        Inventory_Finance_Credit_Limit__c  = sysId.Inventory_Finance_Credit_Limit__c ,
                        Inventory_Finance_Utilization_Amount__c  = sysId.Inventory_Finance_Utilization_Amount__c ,
                        Manufacturer_Name__c  = sysId.Manufacturer_Name__c ,
                        Retail_Finance_Agreement_Signed_Date__c  = sysId.Retail_Finance_Agreement_Signed_Date__c ,
                        Retail_Portfolio__c = sysId.Retail_Portfolio__c,
                        Short_Dealer__c = sysId.Short_Dealer__c,
                        Tax_ID__C = sysId.Tax_ID__C,
                        Client_Dealer_Code__c = sysId.Client_Dealer_Code__c,
                        Type = sysId.Type__c,
                        Net_Investment_Amount__c = sysId.Net_Investment_Amount__c,
                        language__c = sysId.CCAN_Language__c,
                        //PBI:644502:Update System ID Trigger for new Brazil Fields
                        Personal_Identifier__c=sysId.Personal_Identifier__c,
                        //PBI:545164:CF Info: System ID Trigger update
                        Doing_Business_As__c = sysId.Doing_Business_as_Name__c,
                        Account_Manager__c = sysId.Account_Manager__c,
                        Credit_Underwriter__c = sysId.Credit_Underwriter__c,
                        Office_Number__c = sysId.Office_Number__c,
                        Credit_Line_Review_Date__c = sysId.Credit_Line_Review_Date__c,
                        Credit_Qualification__c = sysId.Credit_Qualification__c,
                        Account_Note__c = sysId.Account_Note__c,
                        Commercial_Finance__c = sysId.Source_System__c == 'CCRIS'? true:false,
                        //PBI:622887:Set primary account flag on a partner/vendor account 
                        PI_Primary_Flag__c = sysId.PI_Primary_Flag__c
                    ));
                }
                else{
                    accById.put(sysId.Account__c, new Account(
                        Id = sysId.Account__c,
                        System_Name__c = sysId.System_Name__c,
                        BillingStreet = sysId.Street__c,
                        BillingCity = sysId.City__c,
                        BillingState = sysId.State__c,
                        BillingCountry = sysId.Country__c,
                        BillingPostalCode = sysId.Zip_Postal_Code__c,
                        ATS_ID_s__c = sysId.UNQ_Vendor__c==null?sysId.System_ID__c :entityId,
                        Risk_Rating__c = sysId.Risk_Rating__c,
                        RecordTypeId = RT,
                        US__c = (sysId.Location__c == 'United States'),
                        Canada__c = (sysId.Location__c == 'Canada'),
                        CurrencyIsoCode = sysId.CurrencyIsoCode,
                        //New fields as per #378119
                        Contact_Status__c = sysId.Contact_Status__c,
                        Legal_Entity_Description__c = sysId.Legal_Entity_Description__c,
                        Email__c = sysId.Email__c,
                        Fax = sysId.Fax__c,
                        Inventory_Finance_Agreement_Signed_Date__c = sysId.Inventory_Finance_Agreement_Signed_Date__c,
                        Inventory_Finance_Credit_Limit__c  = sysId.Inventory_Finance_Credit_Limit__c ,
                        Inventory_Finance_Utilization_Amount__c  = sysId.Inventory_Finance_Utilization_Amount__c ,
                        Manufacturer_Name__c  = sysId.Manufacturer_Name__c ,
                        Retail_Finance_Agreement_Signed_Date__c  = sysId.Retail_Finance_Agreement_Signed_Date__c ,
                        Retail_Portfolio__c = sysId.Retail_Portfolio__c,
                        Short_Dealer__c = sysId.Short_Dealer__c,
                        Tax_ID__C = sysId.Tax_ID__C,
                        Client_Dealer_Code__c = sysId.Client_Dealer_Code__c,
                        Type = sysId.Type__c,
                        Net_Investment_Amount__c = sysId.Net_Investment_Amount__c,
                        language__c = sysId.CCAN_Language__c,
                        //PBI:644502:Update System ID Trigger for new Brazil Fields
                        Personal_Identifier__c=sysId.Personal_Identifier__c,
                        //PBI:545164:CF Info: System ID Trigger update
                        Doing_Business_As__c = sysId.Doing_Business_as_Name__c,
                        Account_Manager__c = sysId.Account_Manager__c,
                        Credit_Underwriter__c = sysId.Credit_Underwriter__c,
                        Office_Number__c = sysId.Office_Number__c,
                        Credit_Line_Review_Date__c = sysId.Credit_Line_Review_Date__c,
                        Credit_Qualification__c = sysId.Credit_Qualification__c,
                        Account_Note__c = sysId.Account_Note__c,
                        Commercial_Finance__c = sysId.Source_System__c == 'CCRIS'? true:false,
                        //PBI:622887:Set primary account flag on a partner/vendor account 
                        PI_Primary_Flag__c = sysId.PI_Primary_Flag__c
                    ));
                }
            }
        }
        //update accounts
        if(!accById.isEmpty()){
            update accById.values();
        }
        //If there are still unmatchedSystemIds
        if(unmatchedSysIds.size() > 0){
            streets.clear();
            cities.clear();
            states.clear();
            zipPostalCodes.clear();
            
            for (System_ID__c sysId : unmatchedSysIds) {
                if (String.isNotBlank(sysId.Street__c)
                        && String.isNotBlank(sysId.City__c)
                        && String.isNotBlank(sysId.State__c)
                        && String.isNotBlank(sysId.Zip_Postal_Code__c)) {

                    streets.add(sysId.Street__c);
                    cities.add(sysId.City__c);
                    states.add(sysId.State__c);
                    zipPostalCodes.add(sysId.Zip_Postal_Code__c);
                }
            }
            //Get all possible matching Prospect Account            
            List<Account> existingAccounts = [
                    SELECT  Id, Phone, BillingCity, BillingState, BillingCountry, BillingStreet, BillingPostalCode,
                            OwnerId, Owner.Business_Unit__c, Dealer_Status__c
                    FROM    Account
                    WHERE   RecordTypeId =: recTypeByName.get('Prospect')
                    AND BillingStreet IN: streets
                    AND BillingCity IN: cities
                    AND BillingState IN: states
                    AND BillingPostalCode IN: zipPostalCodes
                    ORDER BY LastModifiedDate DESC
            ];
            
            //Only attempt to match if there are possible matching Prospects
            Map<String, Account> accByKey = new Map<String, Account>();
            Map<String, Boolean> accountFoundAlready = new Map<String, Boolean>();
            //Map the possible matches by a key to easily find from the System ID
            if(existingAccounts.size() > 0){
                for(Account acc : existingAccounts){
                    String key = acc.BillingStreet+'-'+
                            acc.BillingCity+'-'+
                            acc.BillingState+'-'+
                            acc.BillingPostalCode;
                    accByKey.put(key, acc);
                    accountFoundAlready.put(key, false);
                }
            }
            Map<System_ID__c, Account> accToInsertBySysId = new Map<System_ID__c, Account>();
            //Map<System_ID__c, Account> dupAccBySysId = new Map<System_ID__c, Account>();
            //Map<String, Account> createdAccByKey = new Map<String, Account>();
            List<Account> accsToUpdate = new List<Account>();
            List<AccountTeamMember> atmsForInsert = new List<AccountTeamMember>();
            
            Map<String,String> mapOfLocationToRegionName = new Map<String,String>();
            
            for(System_ID__c sysId : unmatchedSysIds){
                if(!String.isEmpty(sysId.Location__c)){
                    mapOfLocationToRegionName.put(sysId.Location__c,null);
                }
            }
            
            for(Region_Association_Index__mdt objRegionAssociationIndex : [SELECT Geographic_Attribute__c,Region_Name__c FROM Region_Association_Index__mdt where Geographic_Attribute__c in :mapOfLocationToRegionName.keySet()]){
                mapOfLocationToRegionName.put(objRegionAssociationIndex.Geographic_Attribute__c,objRegionAssociationIndex.Region_Name__c);
			}
            
            Map<String, Region__c> mapOfRegions = new Map<String,Region__c>();            
            for(Region__c region : [SELECT Id, Name FROM Region__c where Name in : mapOfLocationToRegionName.values() ]){
                mapOfRegions.put(region.Name, region);
            }
            
            //Attempt to match new System IDs to existing Prospects
            for(System_ID__c sysId : unmatchedSysIds){
                String key = sysId.Street__c+'-'+
                        sysId.City__c+'-'+
                        sysId.State__c+'-'+
                        sysId.Zip_Postal_Code__c;
                Account matchedAcc = accByKey.get(key);
                //Account dupAcc = createdAccByKey.get(key);
                Boolean alreadyMatched = accountFoundAlready.get(key);
                //If there is a matching Prospect
                if(matchedAcc != null && !alreadyMatched){
                    sysId.Account__c = matchedAcc.Id;
                    matchedAcc.RecordTypeId = recTypeByName.get(sysId.Type__c);
                    atmsForInsert.add(new AccountTeamMember(
                            AccountId = matchedAcc.Id,
                            UserId = matchedAcc.OwnerId,
                            TeamMemberRole = 'Sales Rep - ' + matchedAcc.Owner.Business_Unit__c
                    ));
                    matchedAcc.OwnerId = Label.IntegrationUserID;
                    //Record Type changed so the Account needs updating
                    accsToUpdate.add(matchedAcc);
                    //Update that this account has already been found
                    accountFoundAlready.put(key, true);
                }else{
                    //No match so create an Account
                    String accName;
                    if(String.isNotBlank(sysId.Legal_Entity_Name__c)){
                        accName = sysId.Legal_Entity_Name__c;
                    }else if(String.isNotBlank(sysId.System_Name__c)){
                        accName = sysId.System_Name__c;
                    }else{
                        //Cannot create an Account without an appropriate name
                        continue;
                    }
                    String entityId;
                    if(String.isNotBlank(sysId.UNQ_Vendor__c) && sysId.Location__c == 'Canada' && String.isNotBlank(sysId.System_ID__c)){
                        entityId = sysId.System_ID__c.substring(0,6) + '.' + sysId.System_ID__c.substring(6,sysId.System_ID__c.length());
                    }else if(String.isNotBlank(sysId.UNQ_Vendor__c) && String.isNotBlank(sysId.System_ID__c)){
                        entityId = sysId.System_ID__c;
                    }
                    String status = dealerStatusMap.get(sysId.Dealer_Status__c);
                    if(status == null && sysId.Location__c == 'Canada'){
                        status = 'Active';
                    }
                    if(status == null && sysId.Location__c != 'Canada'){
                        status = '';
                    }
                    Id RT = sysId.Type__c == 'End User' || sysId.Type__c == 'Prospect' ? recTypeByName.get(sysId.Type__c) : recTypeByName.get('Vendor');
                    //Populate the new Account with values from the new System ID
                    Account createAcc = new Account(
                        Name = accName,
                        System_Name__c = sysId.System_Name__c,
                        Legal_Entity_Name__c = sysId.Legal_Entity_Name__c,
                        Phone = sysId.Phone__c,
                        ATS_ID_s__c = sysId.UNQ_Vendor__c==null?sysId.System_ID__c :entityId,
                        BillingStreet = sysId.Street__c,
                        BillingCity = sysId.City__c,
                        BillingState = sysId.State__c,
                        BillingCountry = sysId.Country__c,
                        BillingPostalCode = sysId.Zip_Postal_Code__c,
                        Risk_Rating__c = sysId.Risk_Rating__c,
                        Dealer_Status__c = status,
                        RecordTypeId = RT,
                        US__c = (sysId.Location__c == 'United States'),
                        Canada__c = (sysId.Location__c == 'Canada'),
                        CurrencyIsoCode = sysId.CurrencyIsoCode,
                        //New fields as per #378119
                        Contact_Status__c = sysId.Contact_Status__c,
                        Legal_Entity_Description__c = sysId.Legal_Entity_Description__c,
                        Email__c = sysId.Email__c,
                        Fax = sysId.Fax__c,
                        Inventory_Finance_Agreement_Signed_Date__c = sysId.Inventory_Finance_Agreement_Signed_Date__c,
                        Inventory_Finance_Credit_Limit__c  = sysId.Inventory_Finance_Credit_Limit__c ,
                        Inventory_Finance_Utilization_Amount__c  = sysId.Inventory_Finance_Utilization_Amount__c ,
                        Manufacturer_Name__c  = sysId.Manufacturer_Name__c ,
                        Retail_Finance_Agreement_Signed_Date__c  = sysId.Retail_Finance_Agreement_Signed_Date__c ,
                        Retail_Portfolio__c = sysId.Retail_Portfolio__c,
                        Short_Dealer__c = sysId.Short_Dealer__c,
                        Tax_ID__C = sysId.Tax_ID__C,
                        Client_Dealer_Code__c = sysId.Client_Dealer_Code__c,
                        Type = sysId.Type__c,
                        Net_Investment_Amount__c = sysId.Net_Investment_Amount__c,
                        language__c = sysId.CCAN_Language__c,
                        //PBI:644502:Update System ID Trigger for new Brazil Fields
                        Personal_Identifier__c=sysId.Personal_Identifier__c,
                        //PBI:545164:CF Info: System ID Trigger update
                        Doing_Business_As__c = sysId.Doing_Business_as_Name__c,
                        Account_Manager__c = sysId.Account_Manager__c,
                        Credit_Underwriter__c = sysId.Credit_Underwriter__c,
                        Office_Number__c = sysId.Office_Number__c,
                        Credit_Line_Review_Date__c = sysId.Credit_Line_Review_Date__c,
                        Credit_Qualification__c = sysId.Credit_Qualification__c,
                        Account_Note__c = sysId.Account_Note__c,
                        Commercial_Finance__c = sysId.Source_System__c == 'CCRIS'? true:false,
                        //PBI:622887:Set primary account flag on a partner/vendor account 
                        PI_Primary_Flag__c = sysId.PI_Primary_Flag__c
                    );
                    // #367590 populate region and region description
                    if(sysId.Location__c != null && mapOfRegions.containsKey(mapOfLocationToRegionName.get(sysId.Location__c))){
                        Region__c region = mapOfRegions.get(mapOfLocationToRegionName.get(sysId.Location__c));
                        createAcc.Region_Relationship__c = region.Id;
                        createAcc.Region_Description__c = region.Name;
                    }
                    accToInsertBySysId.put(sysId, createAcc);
                    //createdAccByKey.put(key, createAcc);
                }
            }
            //Insert the new Accounts
            if(accToInsertBySysId.size() > 0){
                insert accToInsertBySysId.values();
                //Put the new Account Id on the associated System ID
                for(System_ID__c sysId : accToInsertBySysId.keySet()){
                    sysId.Account__c = accToInsertBySysId.get(sysId).Id;
                }
            }
            if(accsToUpdate.size() > 0){
                //Update the Accounts that has a Record Type change
                update accsToUpdate;
            }
            if(atmsForInsert.size() > 0){
                insert atmsForInsert;
            }
        }
    }

    public static Boolean checkForDuplicateEntityId(List<String> entity, String currEntity){
        Boolean duplicates = false;
        for(String s : entity){
            if(s == currEntity){
                duplicates = true;
            }
        }
        return duplicates;
    }

/*******************************************************************
 * PBI789563  : Code change so we do not overwrite Type on an Account Update.
 * Description : Updated existing updateAccount method with new logic
 *******************************************************************/
    public static void updateAccount(List<System_ID__c> sysIdList){
        //Get Account Ids from SysId
        List<Id> accIds = new List<Id>();
        for(System_ID__c sysId :sysIdList){
            if(String.isNotBlank(sysId.Account__c)){
             	accIds.add(sysId.Account__c);   
            }
        }
        //Get Accounts data for update
        Map<String,Account> accMap = new Map<String,Account>([SELECT  Id, Phone, Dealer_Status__c, ATS_ID_s__c, PI_Primary_Flag__c, RecordType.Name
                    											FROM    Account
                    											WHERE   Id IN: accIds
                                                                    FOR UPDATE]);
        Map<Id, Account> mapAccount = new Map<Id, Account>();
        Boolean isSysIdPrimay = false, isAccPiPrimay = false, isSysTypeVDM = false, isAccTypeEUP = false;
        Map<Id, String> accEntityMap = new Map<Id, String>();
        
        //Get field mapping from Metadata
        Map<String,Source_Target_Field_Mapping__mdt> mapFieldMapping = Source_Target_Field_Mapping__mdt.getAll();
		Map<String, String> mapFields = new Map<String, String>();
        
        //Keep required mapping only in Map
        for(Source_Target_Field_Mapping__mdt mapping :mapFieldMapping.values()){
            if(mapping.Source_Object__c.equalsIgnoreCase('System_Id__c') && mapping.Target_Object__c.equalsIgnoreCase('Account')){
            	mapFields.put(mapping.Target_Field__c, mapping.Source_Field__c);
            }
        }
        mapFieldMapping.clear();
        
        for(System_ID__c sysId :sysIdList){
            if(accMap.containsKey(sysId.Account__c) && accMap.get(sysId.Account__c) != NULL){
                Account acc = new Account();
                acc.Id = accMap.get(sysId.Account__c).Id;
                //When Source System's PI_Primary_Flag__c is True
                if(sysId.PI_Primary_Flag__c == true){
                    List<Schema.FieldSetMember> fsSysIdPrimary = SObjectType.Account.fieldSets.SysID_Is_PI_Primary.getFields();
                    //Iterate over FieldSet values and assign values to Account if SysId value is Not null
                    for(Schema.FieldSetMember fsm :fsSysIdPrimary){
                        if(mapFields.containsKey(fsm.getFieldPath()) && sysId.get(mapFields.get(fsm.getFieldPath())) !=NULL && sysId.get(mapFields.get(fsm.getFieldPath())) != ''){
                            acc.put(fsm.getFieldPath(), sysId.get(mapFields.get(fsm.getFieldPath())));
                            isSysIdPrimay = true;
                        }
                    }
                }else if(accMap.containsKey(sysId.Account__c) && accMap.get(sysId.Account__c).PI_Primary_Flag__c 
                         && accMap.get(sysId.Account__c).RecordType.Name =='Vendor' && 
                         (sysId.Type__c=='Vendor' || sysId.Type__c=='Dealer' || sysId.Type__c=='Manufacturer')){//
                    List<Schema.FieldSetMember> fsAccIdPrimary = SObjectType.Account.fieldSets.Account_Is_PI_Primary.getFields();
                    //Iterate over FieldSet values and assign values to Account if SysId value is Not null
                    for(Schema.FieldSetMember fsm :fsAccIdPrimary){
                        if(mapFields.containsKey(fsm.getFieldPath()) && sysId.get(mapFields.get(fsm.getFieldPath())) !=NULL && sysId.get(mapFields.get(fsm.getFieldPath())) != ''){
                            acc.put(fsm.getFieldPath(), sysId.get(mapFields.get(fsm.getFieldPath())));
                            isAccPiPrimay = true;
                        }
                    }
                }else if(accMap.containsKey(sysId.Account__c) && !accMap.get(sysId.Account__c).PI_Primary_Flag__c 
                         && (sysId.Type__c=='Vendor' || sysId.Type__c=='Dealer' || sysId.Type__c=='Manufacturer')){
                    List<Schema.FieldSetMember> fsSysIdTypeVDM = SObjectType.Account.fieldSets.SysId_Type_VNDR_DLR_MFG.getFields();
                    //Iterate over FieldSet values and assign values to Account if SysId value is Not null
                    for(Schema.FieldSetMember fsm :fsSysIdTypeVDM){
                        if(mapFields.containsKey(fsm.getFieldPath()) && sysId.get(mapFields.get(fsm.getFieldPath())) !=NULL && sysId.get(mapFields.get(fsm.getFieldPath())) != ''){
                            acc.put(fsm.getFieldPath(), sysId.get(mapFields.get(fsm.getFieldPath())));
                            isSysTypeVDM = true;
                        }
                    }
                }else if(accMap.containsKey(sysId.Account__c) && !accMap.get(sysId.Account__c).PI_Primary_Flag__c 
                         && (accMap.get(sysId.Account__c).RecordType.Name =='End User' || accMap.get(sysId.Account__c).RecordType.Name =='Prospect')
                            && sysId.Type__c=='End User'){
                    List<Schema.FieldSetMember> fsAccTypeEUP = SObjectType.Account.fieldSets.AccType_EndUser_Prospect.getFields();
                    //Iterate over FieldSet values and assign values to Account if SysId value is Not null
                    for(Schema.FieldSetMember fsm :fsAccTypeEUP){
                        if(mapFields.containsKey(fsm.getFieldPath()) && sysId.get(mapFields.get(fsm.getFieldPath())) !=NULL && sysId.get(mapFields.get(fsm.getFieldPath())) != ''){
                            acc.put(fsm.getFieldPath(), sysId.get(mapFields.get(fsm.getFieldPath())));
                            isAccTypeEUP = true;
                        }
                    }
                }
                
                //Check if Account fields are updated
                if(isSysIdPrimay || isAccPiPrimay || isSysTypeVDM || isAccTypeEUP){
                    //Get entity name
                    String entityId;
                    if(String.isNotBlank(sysId.UNQ_Vendor__c) && sysId.Location__c == 'Canada' && String.isNotBlank(sysId.System_ID__c)){
                        entityId = sysId.System_ID__c.substring(0,6) + '.' + sysId.System_ID__c.substring(6, sysId.System_ID__c.length());
                    }else if(String.isNotBlank(sysId.UNQ_Vendor__c) && String.isNotBlank(sysId.System_ID__c)){
                        entityId = sysId.System_ID__c;
                    }
                    
                    if(accMap.containsKey(sysId.Account__c) && (String.isNotBlank(accMap.get(sysId.Account__c).ATS_ID_s__c) || accEntityMap.containsKey(accMap.get(sysId.Account__c).Id))){
                        String currEntityString;
                        if(accEntityMap.containsKey(accMap.get(sysId.Account__c).Id)){
                            currEntityString = accEntityMap.get(accMap.get(sysId.Account__c).Id);
                        }else{
                            currEntityString = accMap.get(sysId.Account__c).ATS_ID_s__c;
                        }
                        
                        if(String.isNotBlank(sysId.UNQ_Vendor__c) && String.isNotBlank(sysId.System_ID__c)) {
                            if (!checkForDuplicateEntityId(currEntityString.split(';'), entityId) && (currEntityString.length() + entityId.length() < 254)) {
                                entityId = entityId + ';' + currEntityString;
                            }else{
                                entityId = currEntityString;
                            }
                        }else{
                            entityId = currEntityString;
                        }
                        
                        if(accEntityMap.containsKey(accMap.get(sysId.Account__c).Id) || (!accEntityMap.containsKey(accMap.get(sysId.Account__c).Id) && entityId != null)){
                            accEntityMap.put(accMap.get(sysId.Account__c).Id, entityId);
                        }
                    }else if(!accEntityMap.containsKey(accMap.get(sysId.Account__c).Id) && String.isNotBlank(entityId)){
                        accEntityMap.put(accMap.get(sysId.Account__c).Id, entityId);
                    }				
                    //Update Entity Id on Account
                    acc.ATS_ID_s__c = sysId.UNQ_Vendor__c==null?sysId.System_ID__c :entityId;
                    //Update US/Canada flag, RecordType and Dealer Status on Account
                    if(isSysIdPrimay || isSysTypeVDM || isAccTypeEUP){
                        acc.US__c = (sysId.Location__c == 'United States');
                        acc.Canada__c = (sysId.Location__c == 'Canada');
                        
                        Id accRecTypeId; 
                        if(sysId.Type__c == 'End User' || sysId.Type__c == 'Prospect'){
                            accRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(sysId.Type__c).getRecordTypeId();
                        }else{
                            accRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Vendor').getRecordTypeId();
                        }
                        acc.RecordTypeId = accRecTypeId;
                        
                        String status = dealerStatusMap.get(sysId.Dealer_Status__c);
                        if(status == null && sysId.Location__c == 'Canada'){
                            status = 'Active';
                        }
                        if(status == null && sysId.Location__c != 'Canada'){
                            status = accMap.get(sysId.Account__c).Dealer_Status__c;
                        }
                        acc.Dealer_Status__c = status;
                    }
                    //Update Commercial Finance on Account
                    if(isAccPiPrimay || isSysTypeVDM){
                        acc.Commercial_Finance__c = sysId.Source_System__c == 'CCRIS'? true:false;
                    }
                    mapAccount.put(acc.Id, acc);
            	}
            }
        }
        //Update Account
        if(mapAccount.values() != NULL && mapAccount.values().size() > 0){
            Database.SaveResult[] listDSR = Database.UPDATE(mapAccount.values(), false);
            //Error logging
            for(Database.SaveResult sr :listDSR){
                for(Database.Error err :sr.getErrors()){
                    System.debug('Error : '+err.getStatusCode()+' : '+err.getMessage());
                    System.debug('Fields that caused this error : '+err.getFields());
                }
            }
        }
    }
}