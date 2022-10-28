/**
* This class is created to automate the manual process of inserting the Account TeamMember
* for Vendor Accounts, Source_system = 'GDW_US_Desmoines'
*/

global class InsertAccountTeamMember implements System.Schedulable{
    
    global void execute(SchedulableContext sc){
        try{
            String salesSupportUserId = [Select Id from user where isActive=true And UserRole.Name = 'Sales Support (F&A)' limit 1].Id;
            
            Set<string> salesrep_Ids = new Set<String>();
            Set<Id> Account_Id = new Set<Id>();
            List<AccountTeamMember> atmlist = new List<AccountTeamMember>();
            
            List<Account> accToUpdate = new List<Account>();
            Map<Id, List<AccountTeamMember>> actTeamMemberMap = new Map<Id, List<AccountTeamMember>>();
            Map<String, Sales_Rep_ID__c> mapSalesRep = new Map<String, Sales_Rep_ID__c>();
            
            Map<Id, User> User_Map = new Map<Id, User>([ SELECT Id,Business_Unit__c FROM user 
                                                        WHERE DB_Region__c = 'USA - Des Moines'
                                                        AND isActive = TRUE ]);
            
            
            List<System_ID__c> sysIdList = [SELECT Account__c, Account__r.CreatedDate,Account__r.lastModifiedDate, Account__r.Dealer_Status__c,
                                            Account__r.type,Account__r.Short_Dealer__c, Account__r.Vendor_Code__c,
                                            CreatedById,CreatedDate,Inside_Sales_Rep_ID__c, Inside_Sales_Rep_Name__c,
                                            LastModifiedById,LastModifiedDate,Outside_Sales_Rep_ID__c,
                                            Outside_Sales_Rep_Name__c,Source_System_ID__c, Source_System__c 
                                            FROM System_ID__c 
                                            WHERE (Inside_Sales_Rep_ID__c != null OR Outside_Sales_Rep_ID__c != null) 
                                            AND Account__c != null AND Source_System__c='GDW_US_Desmoines' 
                                            AND Dealer_Status__c = 'ACTIVE' AND Account__r.Canada__c = false 
                                            AND Account__r.Dealer_Status__c = 'Active'
                                            AND (CreatedDate = TODAY)
                                            AND (Account__r.CreatedDate = TODAY)];
            //   AND Account__r.type = 'Vendor'];
            
            
            if(sysIdList.size()>0){
                for(System_ID__c sys: sysIdList){
                    Account_Id.add(sys.Account__c);
                    if(sys.Inside_Sales_Rep_ID__c != null){
                        salesrep_Ids.add(sys.Inside_Sales_Rep_ID__c) ;
                    }
                    if(sys.Outside_Sales_Rep_ID__c != null){
                        salesrep_Ids.add(sys.Outside_Sales_Rep_ID__c) ;
                    }
                }
                
                List<Sales_Rep_ID__c> salesRepIds = [SELECT Sales_Rep_ID__c, Sales_Rep__c, Sales_Rep__r.IsActive, Source_System__c
                                                     FROM Sales_Rep_ID__c WHERE Sales_Rep_ID__c IN:salesrep_Ids
                                                     AND Source_System__c = 'GDW_US_Desmoines'
                                                     AND Sales_Rep__r.IsActive = TRUE ];
                
                if(salesRepIds.size()>0){
                    for(Sales_Rep_ID__c srId: salesRepIds){
                        mapSalesRep.put(srId.Sales_Rep_ID__c, srId);
                    }
                }
            }
            
            
            for(System_ID__c sys: sysIdList){
                
                Date crDate = date.newinstance(sys.Account__r.CreatedDate.year(), sys.Account__r.CreatedDate.month(), sys.Account__r.CreatedDate.day());
                Date lmDate = date.newinstance(sys.Account__r.lastModifieddate.year(), sys.Account__r.lastModifieddate.month(), sys.Account__r.lastModifieddate.day());
                
                //insert scenario
                if(crDate == Date.valueOf(System.TODAY())){
                    if(sys.Inside_Sales_Rep_ID__c != null){
                        Sales_Rep_ID__c sRep1 = mapSalesRep.get(sys.Inside_Sales_Rep_ID__c);
                        AccountTeamMember atm = new AccountTeamMember();
                        
                        atm.TeamMemberRole = 'Sales Rep 1 - Food and Agriculture';
                        atm.UserId = sRep1.Sales_Rep__c;
                        atm.AccountId = sys.Account__c;
                        atm.AccountAccessLevel = 'Edit';
                        atm.OpportunityAccessLevel = 'Edit'; 
                        atmlist.add(atm);
                        
                        Account act = new Account();
                        act.Id=sys.Account__c;
                        
                        if(User_Map.get(sRep1.Sales_Rep__c)!=null){
                            if(User_Map.get(sRep1.Sales_Rep__c).Business_Unit__c == 'Food and Agriculture'){
                                act.Food_and_Ag__c = true;
                            }
                            if(User_Map.get(sRep1.Sales_Rep__c).Business_Unit__c == 'Golf & Turf'){
                                act.Golf_and_Turf__c = true;
                            } 
                            accToUpdate.add(act); 
                        }
                        
                    }
                    if(sys.Outside_Sales_Rep_ID__c != null ){
                        Sales_Rep_ID__c sRep2 = mapSalesRep.get(sys.Outside_Sales_Rep_ID__c);
                        AccountTeamMember atm = new AccountTeamMember();
                        
                        atm.TeamMemberRole = 'Sales Rep 2- Food and Agriculture';
                        atm.UserId = sRep2.Sales_Rep__c;
                        atm.AccountId = sys.Account__c;
                        atm.AccountAccessLevel = 'Edit';
                        atm.OpportunityAccessLevel = 'Edit'; 
                        atmlist.add(atm);
                        if(sys.Inside_Sales_Rep_ID__c == null){
                            Account act = new Account();
                            act.Id=sys.Account__c;
                            if(User_Map.get(sRep2.Sales_Rep__c) != null){
                                if(User_Map.get(sRep2.Sales_Rep__c).Business_Unit__c == 'Food and Agriculture'){
                                    act.Food_and_Ag__c = true;
                                }
                                if(User_Map.get(sRep2.Sales_Rep__c).Business_Unit__c == 'Golf & Turf'){
                                    act.Golf_and_Turf__c = true;
                                }
                                accToUpdate.add(act); 
                            }
                        }
                    }
                    List<string> vendor_cods = System.label.Account_Vendor_Code.split(',');
                    
                    if(salesSupportUserId != null && sys.Account__r.type == 'Dealer' && sys.Account__r.Short_Dealer__c != '000105' &&
                       !vendor_cods.contains(sys.Account__r.Vendor_Code__c)){
                           AccountTeamMember atm = new AccountTeamMember();
                           atm.TeamMemberRole = 'Sales Support';
                           atm.UserId = salesSupportUserId;
                           atm.AccountId = sys.Account__c;
                           atm.AccountAccessLevel = 'Edit';
                           atm.OpportunityAccessLevel = 'Edit';
                           atmlist.add(atm);  
                       }               
                }          
            }
            if(atmlist.size()>0){
                insert atmlist;
            }
            
            if(accToUpdate.size()>0){
                update accToUpdate;
            }
        }catch (Exception ex){
            System.debug('Error in  InsertAccountTeamMember at '+ ex.getLineNumber()+' message '+ ex.getMessage() );
        }
    }
    
    
}