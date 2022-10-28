public with sharing class SystemIdTriggerHandler  /* extends TriggerHandler*/
{
//    override public void beforeUpdate()
//    {
//        //AC4
//        Map<id,System_Id__c> mapOfIdAndSystem = new Map<Id,System_Id__c>();
//        list<account> accUpd = new List<account>();
//
//        for(sObject sObj: Trigger.new) {
//            System_ID__c sys = (System_ID__c)sObj;
//            if(sys.account__c!=null){
//                mapOfIdAndSystem.put(sys.account__c,sys);
//            }
//            system.debug('=====mapofid===='+mapOfIdAndSystem);
//        }
//        if(mapOfIdAndSystem !=null){
//            for(Account acc : [Select id,phone FROM Account where id in:mapOfIdAndSystem.keyset()])  {
//                system.debug('=====acc====='+acc);
//                acc.phone = mapOfIdAndSystem.get(acc.id).phone__c;
//                acc.BillingStreet = mapOfIdAndSystem.get(acc.id).Street__c;
//                acc.BillingCity = mapOfIdAndSystem.get(acc.id).City__c;
//                acc.BillingState = mapOfIdAndSystem.get(acc.id).State__c;
//                acc.BillingCountry = mapOfIdAndSystem.get(acc.id).Country__c;
//                acc.System_Name__c = mapOfIdAndSystem.get(acc.id).System_Name__c;
//                acc.Legal_Entity_Name__c = mapOfIdAndSystem.get(acc.id).Legal_Entity_Name__c;
//                acc.Risk_Rating__c = mapOfIdAndSystem.get(acc.id).Risk_Rating__c;
//                acc.BillingPostalCode = mapOfIdAndSystem.get(acc.id).Zip_Postal_Code__c;
//                accupd.add(acc);
//            }
//            if(accupd.size()>0)  {
//                update accupd;
//            }
//        }
//    }
//    override public void beforeInsert()
//    {
//        list<string> phones=new list<string>();
//        list<string> streets=new list<string>();
//        list<string> cities=new list<string>();
//        list<string> states=new list<string>();
//        list<string> countries=new list<string>();
//        list<string> legalNames=new list<string>();
//        list<string> zipPostalCodes = new list<string>();
//
//        list<RecordType> types=[Select Name, Id From RecordType where SobjectType='Account' and (Name='Vendor' or Name='End User' or Name='Prospect')];
//        map<string, Id> mapRecordTypeId=new map<string, Id>();
//        system.debug('Record Type'+types);
//        for(RecordType rt: types)
//        {
//            mapRecordTypeId.put(rt.name, rt.Id);
//        }
//
//        for(sobject sObj : Trigger.new)
//        {
//            System_ID__c sys = (System_ID__c)sObj;
//            if(String.isNotBlank(sys.Phone__c) && String.isNotBlank(sys.Street__c)
//                    && String.isNotBlank(sys.City__c) && String.isNotBlank(sys.State__c)
//                    && String.isNotBlank(sys.Country__c) && String.isNotBlank(sys.Legal_Entity_Name__c)
//                    && String.isNotBlank(sys.Zip_Postal_Code__c)){
//                phones.add(sys.phone__c);
//                streets.add(sys.Street__c);
//                cities.add(sys.city__c);
//                states.add(sys.State__c);
//                countries.add(sys.Country__c);
//                legalNames.add(sys.Legal_Entity_Name__c);
//                zipPostalCodes.add(sys.Zip_Postal_Code__c);
//            }
//        }
//        system.debug('!!!phones='+phones);
//        system.debug('!!!streets='+streets);
//        system.debug('!!!cities='+cities);
//        system.debug('!!!states='+states);
//        system.debug('!!!countries='+countries);
//        system.debug('!!!legalNames='+legalNames);
//        system.debug('!!!zipPostalCodes='+zipPostalCodes);
//
//        list<System_ID__c> existingSysIds=[
//                SELECT
//                    Account__c,
//                    System_Name__c,
//                    id,
//                    phone__c,
//                    city__c,
//                    State__c,
//                    Country__c,
//                    Street__c,
//                    Legal_Entity_Name__c,
//                    LastModifiedDate,
//                    Zip_Postal_Code__c
//                FROM System_ID__c
//                WHERE phone__c IN: phones
//                and city__c IN: cities
//                and State__c IN: states
//                and Country__c IN:countries
//                and Street__c IN:streets
//                and Legal_Entity_Name__c IN: legalNames
//                and Zip_Postal_Code__c IN: zipPostalCodes
//                order by LastModifiedDate DESC];
//        //list<System_ID__c> existingSysIds=[SELECT Account__c ,id,phone__c,city__c,State__c,Country__c,Street__c,Legal_Entity_Name__c,LastModifiedDate,Zip_Postal_Code__c FROM System_ID__c
//         //                                  WHERE phone__c=:phones  order by LastModifiedDate DESC];
//
//        system.debug('=====Existing system id===='+existingSysIds);
//
//        list<System_ID__c> mapUnMatchedSysId=new list<System_ID__c>();
//        Map<Id,Account> accounts=new Map<Id,Account>();
//        for(sobject sObj : Trigger.new)
//        {
//            System_ID__c sys = (System_ID__c)sObj;
//            System_ID__c matchedSysId=null;
//
//            if(!existingSysIds.isEmpty())
//            {
//                system.debug('----------2---------'+existingSysIds);
//                for(System_ID__c temp: existingSysIds)
//                {
//                    if(temp.phone__c==sys.phone__c && temp.Street__c==sys.Street__c && temp.city__c==sys.city__c && temp.State__c==sys.State__c && temp.Country__c==sys.Country__c && temp.Legal_Entity_Name__c==sys.Legal_Entity_Name__c && temp.Zip_Postal_Code__c==sys.Zip_Postal_Code__c)
//                    {
//                        system.debug('------4--------');
//                        if(matchedSysId==null)
//                            matchedSysId=temp;
//
//                        else if(temp.LastModifiedDate>matchedSysId.LastModifiedDate)
//                            matchedSysId=temp;
//                        system.debug('-------matchedSysId-----'+matchedSysId);
//                    }
//                }
//            }
//            system.debug('----------6------'+sys);
//            if(sys.Account__c == null){
//                if(matchedSysId !=null)
//                {
//                    sys.account__c=matchedSysId.account__c;
//                    system.debug('--------7-------'+matchedSysId.account__c);
//                    Account acc=new Account(Id=matchedSysId.account__c);
//                    acc.System_Name__c = sys.System_Name__c;
//                    acc.Phone = sys.phone__c;
//                    acc.BillingStreet = sys.Street__c;
//                    acc.BillingCity = sys.city__c;
//                    acc.BillingState = sys.State__c;
//                    acc.BillingCountry = sys.Country__c;
//                    acc.BillingPostalCode = sys.Zip_Postal_Code__c;
//                    acc.Risk_Rating__c = sys.Risk_Rating__c;
//                    if(sys.Vendor_Id__c!=null)
//                        acc.RecordTypeId=mapRecordTypeId.get('Vendor');
//                    else
//                            acc.RecordTypeId=mapRecordTypeId.get('End User');
//
//                    accounts.put(acc.Id,acc);
//                    system.debug('-------8-------'+accounts);
//                }
//                else{
//                    mapUnMatchedSysId.add(sys);
//                }
//            }
//        }
//        system.debug('mapUnMatchedSysId='+mapUnMatchedSysId.size());
//        update accounts.values();
//
//        phones.clear();
//        streets.clear();
//        cities.clear();
//        states.clear();
//        countries.clear();
//        legalNames.clear();
//        zipPostalCodes.clear();
//        for(sobject sObj : mapUnMatchedSysId)
//        {
//            System_ID__c sys = (System_ID__c)sObj;
//            if(String.isNotBlank(sys.Phone__c) && String.isNotBlank(sys.Street__c)
//                    && String.isNotBlank(sys.City__c) && String.isNotBlank(sys.State__c)
//                    && String.isNotBlank(sys.Country__c) && String.isNotBlank(sys.Legal_Entity_Name__c)
//                    && String.isNotBlank(sys.Zip_Postal_Code__c)){
//                phones.add(sys.phone__c);
//                streets.add(sys.Street__c);
//                cities.add(sys.city__c);
//                states.add(sys.State__c);
//                countries.add(sys.Country__c);
//                legalNames.add(sys.Legal_Entity_Name__c);
//                zipPostalCodes.add(sys.Zip_Postal_Code__c);
//            }
//        }
//
//        list<Account> prospects=new list<Account>();
//        map<System_ID__c, Account> mapSysIdAccount=new map<System_ID__c, Account>();
//        list<Account> existingAccounts=[SELECT id,phone,BillingCity,BillingState,BillingCountry,BillingStreet,BillingPostalCode FROM Account
//                       WHERE recordTypeId=:mapRecordTypeId.get('Prospect') and phone=:phones and BillingCity=:cities and BillingState =:states and BillingStreet =:streets and BillingPostalCode=:zipPostalCodes order by LastModifiedDate DESC];
//
//                for(System_ID__c sys : mapUnMatchedSysId)
//                {
//                    Account matchedAccount=null;
//                    Integer matchAccountsCount=0;
//                        for(Account temp: existingAccounts)
//                        {
//                            if(temp.phone==sys.phone__c && temp.BillingStreet==sys.Street__c && temp.BillingCity==sys.city__c && temp.BillingState==sys.State__c && temp.BillingPostalCode==sys.Zip_Postal_Code__c)
//                            {
//                                ++matchAccountsCount;
//                                matchedAccount=temp;
//                                system.debug('-------matchedAccount-----'+matchedAccount);
//                            }
//                        }
//                        if(matchAccountsCount==1)
//                        {
//                            sys.Account__c=matchedAccount.Id;
//                            if(sys.Vendor_Id__c!=null)
//                                matchedAccount.RecordTypeId=mapRecordTypeId.get('Vendor');
//                            else
//                                matchedAccount.RecordTypeId=mapRecordTypeId.get('End User');
//                            prospects.add(matchedAccount);
//                        }
//                        else
//                        {
//                            Account a=new Account();
//                            if(String.isNotBlank(sys.Legal_Entity_Name__c)){
//                                a.Name=sys.Legal_Entity_Name__c;
//                            }else if(String.isNotBlank(sys.System_Name__c)){
//                                a.Name=sys.System_Name__c;
//                            }else{
//                                continue;
//                            }
//                            a.System_Name__c = sys.System_Name__c;
//                            a.Legal_Entity_Name__c = sys.Legal_Entity_Name__c;
//                            a.BillingStreet = sys.Street__c;
//                            a.BillingCity = sys.City__c;
//                            a.BillingState = sys.State__c;
//                            a.BillingPostalCode = sys.Zip_Postal_Code__c;
//                            a.BillingCountry = sys.Country__c;
//                            a.Phone = sys.Phone__c;
//                            a.Risk_Rating__c = sys.Risk_Rating__c;
//                            if(sys.Vendor_Id__c!=null)
//                                a.RecordTypeId=mapRecordTypeId.get('Vendor');
//                            else
//                                a.RecordTypeId=mapRecordTypeId.get('End User');
//                            mapSysIdAccount.put(sys, a);
//                        }
//                }
//                insert mapSysIdAccount.values();
//                for(System_Id__c sys:mapSysIdAccount.keySet())
//                {
//                    sys.account__c=mapSysIdAccount.get(sys).Id;
//                }
//                update prospects;
//    }
}