/**
 * Created by samuelmeyers on 12/27/18.
 */
/**********************************************************************************************************
   Class :  OpportunityTriggerHelper
   Description : Helper Class for Opportunity

   Date/Sprint		PBI/Description
   PI-22-Q3-19		866653 - Canada Business Unit errors
   PI-22-Q4-21		855444 - As a DSM, CA, & Ag CA Sales Rep, I do not want to see multiple stage and substages with the same date/time stamp.
   PI-22-Q4-22		889196 - Add apex sharing for dealer user (mark moser 10/27/2022)
 ***********************************************************************************************************/
public class OpportunityTriggerHelper {
public static Boolean flagForProgram = true;

public static void helpBeforeInsert(List<Opportunity> newOpps) {
	Id profileId = UserInfo.getProfileId();
	Profile apiProfile = [SELECT Id FROM Profile WHERE Name = 'API Integration' LIMIT 1];
	setInitialValues(newOpps);
	setProgram(newOpps);         //PBI724685 : Changed the sequence of setProgram so that Program value is set before Oppty BU
	//PBI841446 : Skip Stage/Substage translation
	/*List<Opportunity> newFilterOpps = new List<Opportunity>();	//PBI855444 : Skip Stage/Substage translation in Salesforce
	   for(Opportunity opp: newOpps){
	    if(opp.Source_System__c == 'GDW_Wayne'){
	        continue;
	    }
	    newFilterOpps.add(opp);
	   }*/
	//ONLY RUN FOR API INTEGRATION PROFILE
	if (profileId == apiProfile.Id) {
		setSystemUpdateFlag(newOpps);
		//PBI:522080:Commenting this method as its not reachable because source_system is set in Azure:Geetha
		//setLocationInfo(newOpps);
		setOwner(newOpps);
		setAccountAndEndUser(newOpps);
		setBusinessUnit(newOpps);
		//setStage(newOpps);	//PBI855444 : Skip Stage/Substage translation in Salesforce
		//PBI:522080:Commenting this method as Opp type need not set to 'Renewal' anymore:Geetha
		//setType(newOpps);
	} else {
		setNonAPILocationInfo(newOpps);
	}
	updateAccountBusinessFlags(newOpps);
	createAccountRelationships(newOpps);
	createProgramPartnerParty(newOpps);
	//PBI:522080:Modified this sequence as region desc is used in setType and matching criteria and the value in region desc
	//is set in setProgram method only:Geetha
	if (profileId == apiProfile.Id) {
		matchExistingOpportunities(newOpps);
	}
}

public static void helpAfterInsert(Map<Id, Opportunity> newOppMap) {
	updateOpportunityRelationships(newOppMap.values());
	createRelatedAccounts(newOppMap.values());
	insertOppTeamMembers(newOppMap.values());
}

public static void helpBeforeUpdate(Map<Id, Opportunity> oldOppMap, Map<Id, Opportunity> newOppMap) {
	Id profileId = UserInfo.getProfileId();
	Profile apiProfile = [SELECT Id FROM Profile WHERE Name = 'API Integration' LIMIT 1];

	List<Opportunity> oppsGDWProgramChange = new List<Opportunity>();
	for (Opportunity oldOpp : oldOppMap.values()) {
		Opportunity newOpp = newOppMap.get(oldOpp.Id);
		if (oldOpp.UNQ_Program__c != newOpp.UNQ_Program__c && String.isNotBlank(newOpp.UNQ_Program__c)) {
			oppsGDWProgramChange.add(newOpp);
		}
	}

	setAccountAndEndUser(newOppMap.values());
	if(flagForProgram) {
		flagForProgram = false;
		setProgram(oppsGDWProgramChange);
	}

	//Sort into new Opportunities into groups where specific fields have changed and are not null
	List<Opportunity> oppsAccountEndUserChanged = new List<Opportunity>();
	List<Opportunity> oppsVendorProgramChanged = new List<Opportunity>();
	List<Opportunity> oppsProgramChanged = new List<Opportunity>();
	List<Opportunity> oppsAppNumberChanged = new List<Opportunity>();
	List<Opportunity> stageChanged = new List<Opportunity>();
	Map<Id, Id> vendorMap = new Map<Id, Id>();
	Map<Id, Id> endUserMap = new Map<Id, Id>();
	//PBI841446 : Skip Stage Substage translation for Wayne
	//Map<Id, Opportunity> oldOppFilterMap = new Map<Id, Opportunity>();	//PBI855444 : Skip Stage/Substage translation in Salesforce
	//Map<Id, Opportunity> newOppFilterMap = new Map<Id, Opportunity>();	//PBI855444 : Skip Stage/Substage translation in Salesforce

	for (Opportunity oldOpp : oldOppMap.values()) {
		Opportunity newOpp = newOppMap.get(oldOpp.Id);
		if ((oldOpp.End_User__c != newOpp.End_User__c) || (oldOpp.AccountId != newOpp.AccountId)) {
			oppsAccountEndUserChanged.add(newOpp);
		}
		if (oldOpp.Program__c != newOpp.Program__c && newOpp.Program__c != null) {
			oppsProgramChanged.add(newOpp);
		}
		if (oldOpp.Application_Number__c != newOpp.Application_Number__c && newOpp.Application_Number__c != null) {
			oppsAppNumberChanged.add(newOpp);
		}

		if((oldOpp.AccountId != newOpp.AccountId)) {
			vendorMap.put(newOpp.Id, newOpp.AccountId);
		}
		if((oldOpp.End_User__c != newOpp.End_User__c)) {
			endUserMap.put(newOpp.Id, newOpp.End_User__c);
		}
		/*if(newOpp.Source_System__c !='GDW_Wayne'){	//PBI855444 : Skip Stage/Substage translation in Salesforce
		    oldOppFilterMap.put(oldOpp.Id, oldOpp);
		    newOppFilterMap.put(newOpp.Id, newOpp);
		   }*/
	}

	//Only passing Opportunities where End User has changed and is not null
	createAccountRelationships(oppsAccountEndUserChanged);
	//Only passing Opportunities where End User has changed and is not null
	updateOpportunityRelationships(oppsAccountEndUserChanged);
	//Only passing Opportunities where Vendor Program has changed and is not null
	createProgramPartnerParty(oppsProgramChanged);
	//Only passing Opportunities where Application Number has changed and is not null
	//setType(oppsAppNumberChanged);
	updateAccountBusinessFlags(oppsAccountEndUserChanged);
	//Only run for the API Integration Profile
	if (profileId == apiProfile.Id ) {
		deleteOldTeamMembers(oldOppMap,newOppMap);
		changeOppOwner(oldOppMap,newOppMap);
		revertBusinessUnit(oldOppMap, newOppMap);
		//updateStage(oldOppFilterMap,newOppFilterMap); //updateStage(oldOppMap,newOppMap);	//PBI855444 : Skip Stage/Substage translation in Salesforce
		setSystemUpdateFlag(newOppMap.values());
	}
	updateRelatedAccounts(vendorMap, endUserMap);
}

// - Assign Opportunities to the Sales Rep from the Associated Sales Rep Id record
// - if there isn't a matching record, assign the Opportunity to Label.IntegrationUserId
@TestVisible
private static void insertOppTeamMembers(List<Opportunity> opps) {
	Set<String> repIds = new Set<String>();
	Set<String> repSourceSystems = new Set<String>();

	List<OpportunityTeamMember> oppTeamMembers = new List<OpportunityTeamMember>();

	for (Opportunity opp : opps) {
		if (String.isNotBlank(opp.Sales_Rep_ID__c) && String.isNotBlank(opp.Source_System__c)) {
			repIds.add(opp.Sales_Rep_ID__c);
			repSourceSystems.add(opp.Source_System__c);
		}
		if (String.isNotBlank(opp.Sales_Rep_ID_2__c) && String.isNotBlank(opp.Source_System__c)) {
			repIds.add(opp.Sales_Rep_ID_2__c);
			repSourceSystems.add(opp.Source_System__c);
		}
	}

	Map<String, Sales_Rep_ID__c> mapSalesRep = new Map<String, Sales_Rep_ID__c>();
	List<Sales_Rep_ID__c> salesRepIds = [
		SELECT Sales_Rep_ID__c, Sales_Rep__c, Sales_Rep__r.IsActive, Source_System__c
		FROM Sales_Rep_ID__c
		WHERE Sales_Rep_ID__c IN : repIds
		AND Source_System__c IN : repSourceSystems
		AND Sales_Rep__r.IsActive = TRUE
	];


	if (salesRepIds.size() > 0) {
		for (Sales_Rep_ID__c sRep : salesRepIds) {
			mapSalesRep.put(sRep.Sales_Rep_ID__c + '-' + sRep.Source_System__c, sRep);
		}

		for (Opportunity opp : opps) {
			Sales_Rep_ID__c sRep = mapSalesRep.get(opp.Sales_Rep_ID__c + '-' + opp.Source_System__c);
			if (sRep != null) {
				oppTeamMembers.add(new OpportunityTeamMember(
							   OpportunityId = opp.Id,
							   UserId = sRep.Sales_Rep__c,
							   OpportunityAccessLevel = 'Edit',
							   TeamMemberRole = 'Sales Rep - '+ opp.Business_Unit_Description__c
							   ));
			}

			Sales_Rep_ID__c sRep2 = mapSalesRep.get(opp.Sales_Rep_ID_2__c + '-' + opp.Source_System__c);
			if (sRep2 != null) {
				oppTeamMembers.add(new OpportunityTeamMember(
							   OpportunityId = opp.Id,
							   UserId = sRep2.Sales_Rep__c,
							   OpportunityAccessLevel = 'Edit',
							   TeamMemberRole = 'Sales Rep - '+ opp.Business_Unit_Description__c
							   ));
			}
		}
		if(oppTeamMembers.size()>0) {
			insert oppTeamMembers;
		}
	}
}

@TestVisible
private static void deleteOldTeamMembers(Map<Id, Opportunity> oldOppMap, Map<Id, Opportunity> newOppMap) {

	Map<Id,String> oppToRepIdForRep1 = new Map<Id,String>();
	Map<Id,String> oppToRepIdForRep2 = new Map<Id,String>();
	Map<Id,String> rep1SourceSystem = new Map<Id,String>();
	Map<Id,String> rep2SourceSystem = new Map<Id,String>();

	for (Opportunity oldOpp : oldOppMap.values()) {
		Opportunity newOpp = newOppMap.get(oldOpp.Id);

		if ((oldOpp.Sales_Rep_Name__c != newOpp.Sales_Rep_Name__c && newOpp.Sales_Rep_Name__c != null) || (oldOpp.Sales_Rep_ID__c != newOpp.Sales_Rep_ID__c && newOpp.Sales_Rep_ID__c != null)) {
			oppToRepIdForRep1.put(oldOpp.Id,oldOpp.Sales_Rep_ID__c);
			rep1SourceSystem.put(oldOpp.Id, oldOpp.Source_System__c);
		}
		if ((oldOpp.Sales_Rep_Name_2__c != newOpp.Sales_Rep_Name_2__c && newOpp.Sales_Rep_Name_2__c != null) || (oldOpp.Sales_Rep_ID_2__c != newOpp.Sales_Rep_ID_2__c && newOpp.Sales_Rep_ID_2__c != null)) {
			oppToRepIdForRep2.put(oldOpp.Id,oldOpp.Sales_Rep_ID_2__c);
			rep2SourceSystem.put(oldOpp.Id,oldOpp.Source_System__c);
		}
	}

	Map<String, Id> salesRepIDMap = new Map<String, Id>();
	List<String> repsList = new List<String>();
	List<String> repsListsourceSystem = new List<String>();
	repsList.addAll(oppToRepIdForRep1.values());
	repsList.addAll(oppToRepIdForRep2.values());
	repsListsourceSystem.addAll(rep1SourceSystem.values());
	repsListsourceSystem.addAll(rep2SourceSystem.values());

	for (Sales_Rep_ID__c srId : [SELECT Sales_Rep_ID__c, Sales_Rep__c,Source_System__c FROM Sales_Rep_ID__c WHERE Sales_Rep_ID__c in :repsList AND Source_System__c IN:repsListsourceSystem]) {
		salesRepIDMap.put(srId.Sales_Rep_ID__c+'-'+srId.Source_System__c, srId.Sales_Rep__c);
	}

	for(Id oppId : oppToRepIdForRep1.keySet()) {
		oppToRepIdForRep1.put(oppId,salesRepIDMap.get(oppToRepIdForRep1.get(oppId)+'-'+rep1SourceSystem.get(oppId)));
	}
	if(!oppToRepIdForRep1.isEmpty() ) {
		delete [SELECT Id FROM OpportunityTeamMember where userId in : oppToRepIdForRep1.values() AND OpportunityId in : oppToRepIdForRep1.keyset()];
	}

	for(Id oppId : oppToRepIdForRep2.keySet()) {
		oppToRepIdForRep2.put(oppId,salesRepIDMap.get(oppToRepIdForRep2.get(oppId)+'-'+rep2SourceSystem.get(oppId)));
	}
	if(!oppToRepIdForRep2.isEmpty() ) {
		delete [SELECT Id FROM OpportunityTeamMember where userId in : oppToRepIdForRep2.values() AND OpportunityId in : oppToRepIdForRep2.keyset()];
	}
}

@TestVisible
private static void changeOppOwner(Map<Id, Opportunity> oldOppMap, Map<Id, Opportunity> newOppMap) {

	Map<ID,ID> oppOwnerMap = new Map<ID,ID>();
	Set<ID> oldOwner = new Set<ID>();


	List<Opportunity> oppsWithChangedOwners = new List<Opportunity>();
	List<Opportunity> oppsWithChangedRep2 = new List<Opportunity>();
	List<OpportunityTeamMember> oppTeamMembers = new List<OpportunityTeamMember>();
	for (Opportunity oldOpp : oldOppMap.values()) {
		Opportunity newOpp = newOppMap.get(oldOpp.Id);
		if (((oldOpp.Sales_Rep_Name__c != newOpp.Sales_Rep_Name__c) && newOpp.Sales_Rep_Name__c != null) ||
		    ((oldOpp.Sales_Rep_ID__c != newOpp.Sales_Rep_ID__c) && newOpp.Sales_Rep_ID__c != null)) {
			oppsWithChangedOwners.add(newOpp);
		}
		if (((oldOpp.Sales_Rep_Name_2__c != newOpp.Sales_Rep_Name_2__c) && newOpp.Sales_Rep_Name_2__c != null) ||
		    ((oldOpp.Sales_Rep_ID_2__c != newOpp.Sales_Rep_ID_2__c) && newOpp.Sales_Rep_ID_2__c != null)) {
			oppsWithChangedRep2.add(newOpp);
		}
		if (oldOpp.ownerId != newOpp.ownerId) {
			system.debug('**** switching owner ******');
			oppOwnerMap.put(oldOpp.id,oldOpp.ownerId);
			oldOwner.add(oldOpp.ownerId);
		}
	}
	if (!oppsWithChangedOwners.isEmpty()) {
		Map<String, Id> salesRepIDMap = new Map<String, Id>();
		List<String> salesRepIds = new List<String>();
		List<String> ownerSourceSystem = new List<String>();

		for (Opportunity opp : oppsWithChangedOwners) {
			salesRepIds.add(opp.Sales_Rep_ID__c);
			ownerSourceSystem.add(opp.Source_System__c);
		}
		//PBI:549989:On Opportunity update for Sales Rep Id - source system is not considered
		for (Sales_Rep_ID__c srId : [SELECT Sales_Rep_ID__c, Sales_Rep__c, Source_System__c FROM Sales_Rep_ID__c WHERE Sales_Rep_ID__c = :salesRepIds
		                                                                                                                                 AND Source_System__c IN:ownerSourceSystem AND Sales_Rep__r.IsActive = TRUE]) {
			salesRepIDMap.put(srId.Sales_Rep_ID__c+'-'+srId.Source_System__c, srId.Sales_Rep__c);
		}

		for (Opportunity opp : oppsWithChangedOwners) {
			Id currUser = salesRepIDMap.get(opp.Sales_Rep_ID__c+'-'+opp.Source_System__c );

			if (currUser != null) {
				opp.OwnerId = currUser;
				oppTeamMembers.add(new OpportunityTeamMember(
							   OpportunityId = opp.Id,
							   UserId = currUser,
							   OpportunityAccessLevel = 'Edit',
							   TeamMemberRole = 'Sales Rep - '+ opp.Business_Unit_Description__c
							   ));
			}
		}
	}

	if (!oppsWithChangedRep2.isEmpty()) {
		Map<String, Id> salesRepIDMap = new Map<String, Id>();
		List<String> salesRepIds = new List<String>();
		List<String> rep2SourceSystem = new List<String>();

		for (Opportunity opp : oppsWithChangedRep2) {
			salesRepIds.add(opp.Sales_Rep_ID_2__c);
			rep2SourceSystem.add(opp.Source_System__c);
		}
		//PBI:549989:On Opportunity update for Sales Rep Id - source system is not considered
		for (Sales_Rep_ID__c srId : [SELECT Sales_Rep_ID__c, Sales_Rep__c, Source_System__c FROM Sales_Rep_ID__c WHERE Sales_Rep_ID__c = :salesRepIds
		                                                                                                                                 AND Source_System__c IN:rep2SourceSystem AND Sales_Rep__r.IsActive = TRUE]) {
			salesRepIDMap.put(srId.Sales_Rep_ID__c+'-'+srId.Source_System__c, srId.Sales_Rep__c);
		}

		for (Opportunity opp : oppsWithChangedRep2) {
			Id currUser = salesRepIDMap.get(opp.Sales_Rep_ID_2__c+'-'+opp.Source_System__c );
			if (currUser != null) {
				oppTeamMembers.add(new OpportunityTeamMember(
							   OpportunityId = opp.Id,
							   UserId = currUser,
							   OpportunityAccessLevel = 'Edit',
							   TeamMemberRole = 'Sales Rep - '+ opp.Business_Unit_Description__c
							   ));
			}
		}
	}

	if(oppTeamMembers.size()>0) {
		insert oppTeamMembers;
	}

	ID jobID = System.enqueueJob(new AsyncApexSharing( oppOwnerMap, oldOwner, oldOppMap));


}

// - Sets the Updated by System flag
@TestVisible
private static void setSystemUpdateFlag(List<Opportunity> opps) {
	for (Opportunity opp : opps) {
		opp.Updated_by_System__c = true;
	}
}

// - Populate name to a "Filler" value (Real name is set in a Work Flow)
// - Set the Close Date to 90 days after the Application Date
@TestVisible
private static void setInitialValues(List<Opportunity> opps) {
	for (Opportunity opp : opps) {
		if (String.isBlank(opp.Name)) {
			opp.Name = 'Filler';
		}
		//PBI:522080:CloseDate is now set in azure for all Integrated Opps:Geetha
		/*if (opp.Funded_Date__c != null) {
		    opp.CloseDate = opp.Funded_Date__c;
		   } */
		if (opp.CloseDate == null && opp.Application_Date__c != null) {
			opp.CloseDate = Date.valueOf(opp.Application_Date__c).addDays(90);
		}
	}
}


//PBI:522080:This method is not reachable as source_system__c is set in azure for all Integrated Opps:Geetha
/*@TestVisible
   private static void setLocationInfo(List<Opportunity> opps) {
    for (Opportunity opp : opps) {
        // Added per DMC-23
        if (String.isBlank(opp.Source_System__c)) {
            opp.Source_System__c = 'GDW_WAYNE';
            opp.Location__c = 'United States';
            opp.Application_Number__c = opp.UNQ_Opportunity__c;
            opp.CurrencyIsoCode = 'USD';
        }
    }
   }*/

@TestVisible
private static void setNonAPILocationInfo(List<Opportunity> opps) {
	Id canadaManagerId = [SELECT Id FROM UserRole WHERE Name = 'Canada Sales'].Id;
	Set<Id> subIds = RoleUtility.getAllSubRoleIds(new Set<Id> {
			canadaManagerId
		});
	subIds.add(canadaManagerId);

	for (Opportunity opp : opps) {
		if (subIds.contains(UserInfo.getUserRoleId())) {
			opp.Location__c = 'Canada';
		} else {
			opp.Location__c = 'United States';
		}
		opp.Source_System__c = 'User Created';
	}
}

// - Populate Program lookup from records with matching Program Codes
@TestVisible
private static void setProgram(List<Opportunity> opps) {
	Set<String> programCodes = new Set<String>();

	List<Opportunity> oppsWhereUNQProgramExists = new List<Opportunity>();

	//Opportunity.UNQ_Program__c IS BLANK and Opportunity.Region_Description__c IS NOT BLANK and Opportunity.Business_Unit_Description__c IS NOT BLANK (New functionality)
	List<Opportunity> oppsWhereRD_and_BUDIsNotBlank = new List<Opportunity>();

	//Opportunity.Program__c IS NOT BLANK and Opportunity.UNQ_Program__c IS BLANK
	List<Opportunity> oppsWhereProgramNotNull = new List<Opportunity>();

	//if all else fails - Check that User.ProfileName NOT EQUAL to "API Integration"
	List<Opportunity> leftOpps = new List<Opportunity>();

	Id profileId = UserInfo.getProfileId();
	Profile apiProfile = [SELECT Id FROM Profile WHERE Name = 'API Integration' LIMIT 1];

	for (Opportunity opp : opps) {
		if (String.isNotBlank(opp.UNQ_Program__c)) {
			programCodes.add(opp.UNQ_Program__c);
			oppsWhereUNQProgramExists.add(opp);
		}else if(opp.Program__c != null ) {
			oppsWhereProgramNotNull.add(opp);
		}else{
			leftOpps.add(opp);
		}
	}

	if(oppsWhereUNQProgramExists.size()>0) {
		setProgramInfoFromUNQProgram(oppsWhereUNQProgramExists, programCodes);
	}

	if(oppsWhereProgramNotNull.size()>0) {
		setProgramInfoFromProgram(oppsWhereProgramNotNull);
	}

	if(leftOpps.size()>0 && profileId != apiProfile.Id) {
		setRegionRelationshipAndBusinessUnitFromUser(leftOpps);
	}
}

@TestVisible
private static void setRegionRelationshipAndBusinessUnitFromUser(List<Opportunity> opps){

	List<Region_Assignment__c> regionAssignments = [Select id,Region__c,Region__r.Name
	                                                From Region_Assignment__c
	                                                where user__c = : UserInfo.getUserId()];

	List<Business_Unit_Assignment__c> businessUnitAssignments = [SELECT Id,Business_Unit__c,Business_Unit__r.Opportunity_Record_Type_ID__c,Business_Unit__r.Name,Business_Unit__r.Parent_Business_Unit__r.Name
	                                                             FROM Business_Unit_Assignment__c
	                                                             WHERE user__c = : UserInfo.getUserId()];

	if(!businessUnitAssignments.isEmpty()) {
		for(Opportunity opp : opps) {
			if(businessUnitAssignments[0].Business_Unit__r != null && businessUnitAssignments[0].Business_Unit__r.Parent_Business_Unit__r != null) {
				opp.Business_Unit__c = businessUnitAssignments[0].Business_Unit__c;
				opp.Business_Unit_Description__c = businessUnitAssignments[0].Business_Unit__r.Name;
				opp.Legal_Entity_Description__c  = businessUnitAssignments[0].Business_Unit__r.Parent_Business_Unit__r.Name;
				//Commenting as per Brent Ask to not set RT from BU
				/*if(businessUnitAssignments[0].Business_Unit__r.Opportunity_Record_Type_ID__c != null){
				   opp.RecordTypeId = businessUnitAssignments[0].Business_Unit__r.Opportunity_Record_Type_ID__c;
				   }*/
			}
		}
	}

	if(!regionAssignments.isEmpty()) {
		for(Opportunity opp : opps) {
			opp.Region_Relationship__c = regionAssignments[0].Region__c;
			opp.Region_Description__c = regionAssignments[0].Region__r.Name;
		}
	}

}

@TestVisible
private static void setProgramInfoFromProgram(List<Opportunity> opps){
	Map<Id,Program__c> mapOfProgramIdToProgram = new Map<Id,Program__c>();
	for (Opportunity opp : opps) {
		mapOfProgramIdToProgram.put(opp.Program__c, null);
	}
	for(Program__c program : [SELECT Region__c,Business_Unit__c,Business_Unit__r.Opportunity_Record_Type_ID__c,
	                          Region_Description__c,Legal_Entity_Description__c,Business_Unit_Description__c
	                          FROM Program__c
	                          WHERE Id in :mapOfProgramIdToProgram.keySet()]) {
		mapOfProgramIdToProgram.put(program.id, program);
	}
	for (Opportunity opp : opps) {
		Program__c program = mapOfProgramIdToProgram.get(opp.Program__c);
		opp.Region_Relationship__c = program.Region__c;
		opp.Region_Description__c = program.Region_Description__c;
		opp.Legal_Entity_Description__c = program.Legal_Entity_Description__c;
		opp.Business_Unit__c = program.Business_Unit__c;
		opp.Business_Unit_Description__c = program.Business_Unit_Description__c;
		//PBI:434119:Setting new recordtype in Workflow: Geetha
		/* if(program.Business_Unit__r.Opportunity_Record_Type_ID__c != null){
		   opp.RecordTypeId = program.Business_Unit__r.Opportunity_Record_Type_ID__c;
		   }*/
	}
}

@TestVisible
private static void setRegionRelationshipAndBusinessUnit(List<Opportunity> opps) {

	Map<String,String> mapOfRegionDescriptionToRegionName = new Map<String,String>();
	Map<String,String> mapOfBUDescriptionToBUName = new Map<String,String>();
	for (Opportunity opp : opps) {
		mapOfRegionDescriptionToRegionName.put(opp.Region_Description__c,null);
		mapOfBUDescriptionToBUName.put(opp.Business_Unit_Description__c,null);
	}
	mapOfRegionDescriptionToRegionName.put('Unknown','Unknown');
	mapOfBUDescriptionToBUName.put('Unknown','Unknown');
	for(Business_Unit_Association_Index__mdt objBUAI:[SELECT Id, Business_Unit_Attribute__c, Business_Unit_Name__c
	                                                  FROM Business_Unit_Association_Index__mdt
	                                                  WHERE Business_Unit_Attribute__c in : mapOfBUDescriptionToBUName.keyset()]) {
		mapOfBUDescriptionToBUName.put(objBUAI.Business_Unit_Attribute__c,objBUAI.Business_Unit_Name__c);
	}

	Map<String, Business_Unit__c> mapOfBUs = new Map<String,Business_Unit__c>();
	Map<String, Business_Unit__c> mapOfBUWithLE = new Map<String,Business_Unit__c>();
	for(Business_Unit__c bu : [SELECT Id,Name,Parent_Business_Unit__r.Name,Opportunity_Record_Type_ID__c
	                           FROM Business_Unit__c
	                           WHERE Name in : mapOfBUDescriptionToBUName.values() ]) {
		if(bu.Parent_Business_Unit__r.Name != null) {
			mapOfBUWithLE.put(bu.Name+bu.Parent_Business_Unit__r.Name, bu);
		}
		mapOfBUs.put(bu.Name, bu);
	}

	for(Region_Association_Index__mdt objRegionAssociationIndex : [SELECT Geographic_Attribute__c,Region_Name__c
	                                                               FROM Region_Association_Index__mdt
	                                                               WHERE Geographic_Attribute__c in :mapOfRegionDescriptionToRegionName.keySet()]) {
		mapOfRegionDescriptionToRegionName.put(objRegionAssociationIndex.Geographic_Attribute__c,objRegionAssociationIndex.Region_Name__c);
	}

	Map<String, Region__c> mapOfRegions = new Map<String,Region__c>();
	for(Region__c region : [SELECT Id, Name FROM Region__c where Name in : mapOfRegionDescriptionToRegionName.values() ]) {
		mapOfRegions.put(region.Name, region);
	}
	for (Opportunity opp : opps) {
		if(mapOfRegionDescriptionToRegionName.containsKey(opp.Region_Description__c)) {
			opp.Region_Relationship__c = mapOfRegions.get(mapOfRegionDescriptionToRegionName.get(opp.Region_Description__c)).Id;
			opp.Region_Description__c = mapOfRegions.get(mapOfRegionDescriptionToRegionName.get(opp.Region_Description__c)).Name;

		}else if(mapOfRegionDescriptionToRegionName.containsKey('Unknown')) {
			opp.Region_Description__c = mapOfRegions.get(mapOfRegionDescriptionToRegionName.get('Unknown')).Name;
			opp.Region_Relationship__c = mapOfRegions.get(mapOfRegionDescriptionToRegionName.get('Unknown')).Id;
		}
		if(String.isBlank(opp.Legal_Entity_Description__c) && mapOfBUDescriptionToBUName.containsKey(opp.Business_Unit_Description__c)
		   && mapOfBUS.containsKey(mapOfBUDescriptionToBUName.get(opp.Business_Unit_Description__c))) {

			Business_Unit__c bu = mapOfBUs.get(mapOfBUDescriptionToBUName.get(opp.Business_Unit_Description__c));
			//PBI:434119:Setting new recordtype in Workflow: Geetha
			//opp.RecordTypeId = bu.Opportunity_Record_Type_ID__c;
			opp.Business_Unit__c = bu.Id;
			opp.Legal_Entity_Description__c = bu.Parent_Business_Unit__r.Name;
			opp.Business_Unit_Description__c = bu.Name;
		}else if(!String.isBlank(opp.Legal_Entity_Description__c) && mapOfBUDescriptionToBUName.containsKey(opp.Business_Unit_Description__c)
		         && mapOfBuWithLE.containsKey(mapOfBUDescriptionToBUName.get(opp.Business_Unit_Description__c)+opp.Legal_Entity_Description__c)) {
			Business_Unit__c bu = mapOfBuWithLE.get(mapOfBUDescriptionToBUName.get(opp.Business_Unit_Description__c)+opp.Legal_Entity_Description__c);
			//PBI:434119:Setting new recordtype in Workflow: Geetha
			//opp.RecordTypeId = bu.Opportunity_Record_Type_ID__c;
			opp.Business_Unit__c = bu.Id;
			opp.Legal_Entity_Description__c = bu.Parent_Business_Unit__r.Name;
			opp.Business_Unit_Description__c = bu.Name;
		}else if(mapOfBUDescriptionToBUName.containsKey('Unknown')) {
			opp.Business_Unit__c = mapOfBUs.get(mapOfBUDescriptionToBUName.get('Unknown')).Id;
			opp.Business_Unit_Description__c = mapOfBUs.get(mapOfBUDescriptionToBUName.get('Unknown')).Name;
		}
	}
}

@TestVisible
private static void setProgramInfoFromUNQProgram(List<Opportunity> opps,Set<String> programCodes) {
	if (programCodes.size() > 0) {
		List<Program__c> programs = [
			SELECT Id, UNQ_Program__c, Region__c,Region__r.Name, Business_Unit__r.Name,
			Business_Unit__c, Business_Unit__r.Opportunity_Record_Type_ID__c, Legal_Entity_Description__c
			FROM Program__c
			WHERE UNQ_Program__c IN : programCodes
		];
		Map<String, Program__c> programIdByProgramCode = new Map<String, Program__c>();
		for (Program__c program : programs) {
			programIdByProgramCode.put(program.UNQ_Program__c, program);
		}

		List<Opportunity> oppsWhereRD_and_BUDIsNotBlank = new List<Opportunity>();

		for (Opportunity opp : opps) {
			Program__c prog = programIdByProgramCode.get(opp.UNQ_Program__c);
			if(prog != null) {
				opp.Program__c = prog.Id;
				if(String.isNotBlank(opp.Region_Description__c) && String.isNotBlank(opp.Business_Unit_Description__c )) {
					oppsWhereRD_and_BUDIsNotBlank.add(opp);
				}else{
					opp.Region_Relationship__c = prog.Region__c;
					opp.Region_Description__c = prog.Region__r.Name;
					opp.Business_Unit__c = prog.Business_Unit__c;
					opp.Business_Unit_Description__c = prog.Business_Unit__r.Name;
					opp.Legal_Entity_Description__c = prog.Legal_Entity_Description__c;

					//PBI:434119:Setting new recordtype in Workflow: Geetha
					/*if(prog.Business_Unit__r.Opportunity_Record_Type_ID__c != null){
					   opp.RecordTypeId = prog.Business_Unit__r.Opportunity_Record_Type_ID__c;
					   }*/
				}
			}
		}

		if(oppsWhereRD_and_BUDIsNotBlank.size()>0) {
			setRegionRelationshipAndBusinessUnit(oppsWhereRD_and_BUDIsNotBlank);
		}
	}
}

// - Find possible matches that already exist in Salesforce for each Opportunity
// - if a match exists, populate Existing Match with the Id of the Opportunity it is matched to instead of updating
//   the Matched Opportunity directly to avoid record locking when running batches concurrently with Bulk API. The
//   Updating of the actual Opportunity records happens in a Scheduled Batch Job
//   (executed in PostTriggerBatchScheduler).
//   PBI:522080:Replaced location__c with Region_Description__c as location__c is not set anywhere:Geetha
//   PBI:531473:Replaced account with Enduser account
@TestVisible
private static void matchExistingOpportunities(List<Opportunity> opps) {
	Set<String> repIds = new Set<String>();
	Set<String> accountIds = new Set<String>();
	Set<String> euPhones = new Set<String>();
	Set<String> appNumbers = new Set<String>();
	Set<String> locations = new Set<String>();
	Set<Double> amounts = new Set<Double>();

	List<Opportunity> oppsToMatch = new List<Opportunity>();
	Integer match1Count = 0;
	Integer match2Count = 0;
	Integer match3Count = 0;

	//Collect data to look for potential opportunity matches
	for (Opportunity opp : opps) {
		Boolean hasAccount = opp.End_User__c != null;
		Boolean hasSalesRepId = opp.OwnerId != null;
		Boolean hasAmount = opp.Amount != null;
		Boolean hasAppNumber = String.isNotBlank(opp.Application_Number__c);
		Boolean hasLocation = String.isNotBlank(opp.Region_Description__c);
		Boolean hasEndUserPhone = String.isNotBlank(opp.End_User_Phone__c);

		// * MATCH CONDITION PRIORITY *
		// - 1. The Application Number
		// - 2. The Enduser Account, Sales Rep, End User Phone, Amount and Region Description are a match
		// - 3. The Enduser Account, Sales Rep, Amount and Region Description are a match
		Boolean canMatch1 = hasAppNumber;
		Boolean canMatch2 = hasAccount && hasSalesRepId && hasAmount && hasEndUserPhone && hasLocation;
		Boolean canMatch3 = hasAccount && hasSalesRepId && hasAmount && hasLocation;

		if (canMatch1 || canMatch2 || canMatch3) {
			oppsToMatch.add(opp);
			if (canMatch1) {
				appNumbers.add(opp.Application_Number__c);
				//locations.add(opp.Region_Description__c);
				match1Count++;
			}
			if (canMatch2) {
				accountIds.add(opp.End_User__c);
				repIds.add(opp.OwnerId);
				amounts.add(opp.Amount.setScale(2));
				euPhones.add(opp.End_User_Phone__c);
				locations.add(opp.Region_Description__c);
				match2Count++;
			}
			if (canMatch3) {
				accountIds.add(opp.End_User__c);
				repIds.add(opp.OwnerId);
				amounts.add(opp.Amount.setScale(2));
				locations.add(opp.Region_Description__c);
				match3Count++;
			}
		}
	}

	if (oppsToMatch.size() > 0) {
		//ATTEMPTING TO MAKE QUERIES MORE SELECTIVE BY BREAKING OUT INTO 3 QUERIES
		List<Opportunity> possibleMatches = new List<Opportunity>();
		Map<Id, Opportunity> possOpps = new Map<Id, Opportunity>();

		if (match1Count > 0) {
			List<Opportunity> matches = [
				SELECT Id, End_User__c, Amount, Application_Number__c, End_User_Phone__c, Location__c, OwnerId, Source_System__c, Region_Description__c
				FROM Opportunity
				WHERE Updated_by_System__c = FALSE
				                             // AND Region_Description__c IN:locations
				                             AND Application_Number__c IN : appNumbers
				                             ORDER BY LastModifiedDate
			];
			if (matches.size() > 0) {
				possOpps.putAll(matches);
			}
		}

		if (match2Count > 0) {
			List<Opportunity> matches = [
				SELECT Id, End_User__c, Amount, Application_Number__c, End_User_Phone__c, Location__c, OwnerId, Source_System__c, Region_Description__c
				FROM Opportunity
				WHERE Updated_by_System__c = FALSE
				                             AND Region_Description__c IN : locations
				                             AND OwnerId IN : repIds
				                             AND End_User__c IN : accountIds
				                             AND End_User_Phone__c IN : euPhones
				                             AND Amount IN : amounts
				                             ORDER BY LastModifiedDate
			];
			if (matches.size() > 0) {
				possOpps.putAll(matches);
			}
		}

		if (match3Count > 0) {
			List<Opportunity> matches = [
				SELECT Id, End_User__c, Amount, Application_Number__c, End_User_Phone__c, Location__c, OwnerId, Source_System__c, Region_Description__c
				FROM Opportunity
				WHERE Updated_by_System__c = FALSE
				                             AND Region_Description__c IN : locations
				                             AND OwnerId IN : repIds
				                             AND End_User__c IN : accountIds
				                             AND Amount IN : amounts
				                             ORDER BY LastModifiedDate
			];

			if (matches.size() > 0) {
				possOpps.putAll(matches);
			}
		}

		if (possOpps.size() > 0) {
			possibleMatches = possOpps.values();
		}

		//END CHANGE

		//if there are no Possible Matches, there is no need to check for a match
		if (possibleMatches != null && possibleMatches.size() > 0) {
			Map<String, Opportunity> oppsByAppNumLocation = new Map<String, Opportunity>();
			Map<String, Opportunity> oppsByAccRepPhoneAmountLocation = new Map<String, Opportunity>();
			Map<String, Opportunity> oppsByAccRepAmountLocation = new Map<String, Opportunity>();

			//Map each Opportunity (based on match condition priority) by the match criteria fields concatenated
			for (Opportunity opp : possibleMatches) {

				Boolean hasAccount = opp.End_User__c != null;
				Boolean hasSalesRepId = opp.OwnerId != null;
				Boolean hasAmount = opp.Amount != null;
				Boolean hasAppNumber = String.isNotBlank(opp.Application_Number__c);
				Boolean hasLocation = String.isNotBlank(opp.Region_Description__c);
				Boolean hasEndUserPhone = String.isNotBlank(opp.End_User_Phone__c);

				// * MATCH CONDITION PRIORITY *
				// - 1. The Application Number
				// - 2. The Enduser Account, Sales Rep, End User Phone, Amount and Region Description are a match
				// - 3. The Enduser Account, Sales Rep, Amount and Region Description are a match
				Boolean canMatch1 = hasAppNumber;
				Boolean canMatch2 = hasAccount && hasSalesRepId && hasAmount && hasEndUserPhone && hasLocation;
				Boolean canMatch3 = hasAccount && hasSalesRepId && hasAmount && hasLocation;

				if (canMatch1) {
					String key = opp.Application_Number__c;
					oppsByAppNumLocation.put(key, opp);
				}
				if (canMatch2) {
					String key = opp.End_User__c + '-' + opp.OwnerId + '-' + opp.Amount + '-' + opp.End_User_Phone__c + '-' + opp.Region_Description__c;
					oppsByAccRepPhoneAmountLocation.put(key, opp);
				}
				if (canMatch3) {
					String key = opp.End_User__c + '-' + opp.OwnerId + '-' + opp.Amount + '-' + opp.Region_Description__c;
					oppsByAccRepAmountLocation.put(key, opp);

				}
			}

			//Only check the Opps that could have a match, and find their match based on match condition priority
			for (Opportunity opp : oppsToMatch) {
				if (oppsByAppNumLocation.get(opp.Application_Number__c) != null) {
					Opportunity match = oppsByAppNumLocation.get(opp.Application_Number__c);
					opp.Existing_Match__c = match.Id;
					opp.Source_System__c = match.Source_System__c;
				} else if (oppsByAccRepPhoneAmountLocation.get(opp.End_User__c + '-' + opp.OwnerId + '-' + opp.Amount + '-' + opp.End_User_Phone__c + '-' + opp.Region_Description__c) != null) {
					Opportunity match = oppsByAccRepPhoneAmountLocation.get(opp.End_User__c + '-' + opp.OwnerId + '-' + opp.Amount + '-' + opp.End_User_Phone__c + '-' + opp.Region_Description__c);
					opp.Existing_Match__c = match.Id;
					opp.Source_System__c = match.Source_System__c;
				} else if (oppsByAccRepAmountLocation.get(opp.End_User__c + '-' + opp.OwnerId + '-' + opp.Amount + '-' + opp.Region_Description__c) != null) {
					Opportunity match = oppsByAccRepAmountLocation.get(opp.End_User__c + '-' + opp.OwnerId + '-' + opp.Amount + '-' + opp.Region_Description__c);
					opp.Existing_Match__c = match.Id;
					opp.Source_System__c = match.Source_System__c;
				}
			}
		}
	}
}

@TestVisible
private static void createRelatedAccounts(List<Opportunity> opps){
	List<Related_Account__c> relsToInsert = new List<Related_Account__c>();
	for(Opportunity opp : opps) {
		if(opp.End_User__c != null) {
			Related_Account__c euRel = new Related_Account__c(
				Opportunity__c = opp.Id,
				Account__c = opp.End_User__c,
				Type__c ='End User'
				);
			relsToInsert.add(euRel);
		}
		if(opp.AccountId != null) {
			Related_Account__c vRel = new Related_Account__c(
				Opportunity__c = opp.Id,
				Account__c = opp.AccountId,
				Type__c = 'Vendor'
				);
			relsToInsert.add(vRel);
		}
	}
	if(!relsToInsert.isEmpty()) {
		insert relsToInsert;
	}

}

@TestVisible
private static void updateRelatedAccounts(Map<Id, Id> vendorMap, Map<Id, Id> endUserMap){
	List<Related_Account__c> vendorRel = new List<Related_Account__c>();
	List<Related_Account__c> endUserRel = new List<Related_Account__c>();
	if(vendorMap != null && !vendorMap.isEmpty()) {
		vendorRel = [
			SELECT Opportunity__c, Account__c
			FROM Related_Account__c
			WHERE Type__c = 'Vendor' AND Opportunity__c IN : vendorMap.keySet()
		];
	}

	if(endUserMap != null && !endUserMap.isEmpty()) {
		endUserRel = [
			SELECT Opportunity__c, Account__c
			FROM Related_Account__c
			WHERE Type__c = 'End User' AND Opportunity__c IN : endUserMap.keySet()
		];
	}

	Map<Id, Related_Account__c> vendorMapExisting = new Map<Id, Related_Account__c>();
	Map<Id, Related_Account__c> endUserMapExisting = new Map<Id, Related_Account__c>();
	List<Related_Account__c> relsToUpdate = new List<Related_Account__c>();
	List<Related_Account__c> relsToInsert = new List<Related_Account__c>();

	for(Related_Account__c rel : vendorRel) {
		vendorMapExisting.put(rel.Opportunity__c, rel);
	}

	for(Related_Account__c rel : endUserRel) {
		endUserMapExisting.put(rel.Opportunity__c, rel);
	}

	if(vendorMap != null && !vendorMap.isEmpty()) {
		for (Id oId : vendorMap.keySet()) {
			Related_Account__c relToCheck = vendorMapExisting.get(oId);
			if (relToCheck != null) {
				if (relToCheck.Account__c != vendorMap.get(oId)) {
					relToCheck.Account__c = vendorMap.get(oId);
					relsToUpdate.add(relToCheck);
				}
			} else {
				Related_Account__c relToInsert = new Related_Account__c(
					Opportunity__c = oId,
					Account__c = vendorMap.get(oId),
					Type__c = 'Vendor'
					);
				relsToInsert.add(relToInsert);
			}

		}
	}
	if(endUserMap != null && !endUserMap.isEmpty()) {
		for (Id oId : endUserMap.keySet()) {
			Related_Account__c relToCheck = endUserMapExisting.get(oId);
			if (relToCheck != null) {
				if (relToCheck.Account__c != endUserMap.get(oId)) {
					relToCheck.Account__c = endUserMap.get(oId);
					relsToUpdate.add(relToCheck);
				}
			} else {
				Related_Account__c relToInsert = new Related_Account__c(
					Opportunity__c = oId,
					Account__c = endUserMap.get(oId),
					Type__c = 'End User'
					);
				relsToInsert.add(relToInsert);
			}
		}
	}

	if(!relsToUpdate.isEmpty()) {
		update relsToUpdate;
	}

	if(!relsToInsert.isEmpty()) {
		insert relsToInsert;
	}
}
// - Populate Account from System Id record where sysId.UNQ_Vendor__c = opp.UNQ_Vendor__c
// - Populate End User from System Id record where sysId.UNQ_Customer__c = opp.UNQ_Customer__c
@TestVisible
private static void setAccountAndEndUser(List<Opportunity> opps) {
	Set<String> vendorNos = new Set<String>();
	Set<String> customerCodes = new Set<String>();
	Set<Id> ownerIds = new Set<Id>();

	List<Opportunity> oppsToSetAccount = new List<Opportunity>();
	List<Opportunity> oppsToSetEndUser = new List<Opportunity>();

	//Get Vendor Numbers, Customer Codes, and Opportunities that will be Updated
	for (Opportunity opp : opps) {
		if (String.isNotBlank(opp.UNQ_Vendor__c)) {
			vendorNos.add(opp.UNQ_Vendor__c);
			oppsToSetAccount.add(opp);
		}
		if (String.isNotBlank(opp.UNQ_Customer__c)) {
			customerCodes.add(opp.UNQ_Customer__c);
			oppsToSetEndUser.add(opp);
		}
		ownerIds.add(opp.OwnerId);
	}

	List<System_ID__c> systemIds = [
		SELECT Id, Account__c, Account__r.Phone, UNQ_Vendor__c, UNQ_Customer__c, Account__r.Name, Account__r.Owner.IsActive
		FROM System_ID__c
		WHERE UNQ_Vendor__c IN : vendorNos
		OR UNQ_Customer__c IN : customerCodes
	];
	Map<Id, User> ownersById = new Map<Id, User>([SELECT Id, IsActive FROM User WHERE Id IN: ownerIds]);

	//if System Ids were found, set Account and End User
	if (systemIds.size() > 0) {
		Map<String, System_ID__c> systemIdByVendorNo = new Map<String, System_ID__c>();
		Map<String, System_ID__c> systemIdByCustomerCode = new Map<String, System_ID__c>();

		for (System_ID__c sysId : systemIds) {
			if (String.isNotBlank(sysId.UNQ_Vendor__c)) {
				systemIdByVendorNo.put(sysId.UNQ_Vendor__c, sysId);
			}
			if (String.isNotBlank(sysId.UNQ_Customer__c)) {
				systemIdByCustomerCode.put(sysId.UNQ_Customer__c, sysId);
			}
		}


		//Set Account
		for (Opportunity opp : oppsToSetAccount) {
			System_ID__c sysId = systemIdByVendorNo.get(opp.UNQ_Vendor__c);
			if (sysId != null) {
				opp.Vendor_ID__c = sysId.Id;
				opp.AccountId = sysId.Account__c;
				if (ownersById.get(opp.OwnerId) != null && !ownersById.get(opp.OwnerId).IsActive) {
					opp.OwnerId = Label.IntegrationUserID;
				}
			}
		}

		//Set End User
		for (Opportunity opp : oppsToSetEndUser) {
			System_ID__c sysId = systemIdByCustomerCode.get(opp.UNQ_Customer__c);
			if (sysId != null) {
				opp.Customer_Code__c = sysId.Id;
				opp.End_User__c = sysId.Account__c;
				if (String.isBlank(sysId.Account__r.Phone) && String.isBlank(opp.End_User_Phone__c)) {
					opp.End_User_Phone__c = 'Unknown';
				} else if (String.isBlank(opp.End_User_Phone__c)) {
					opp.End_User_Phone__c = sysId.Account__r.Phone;
				}
				//opp.End_User_Company_Name__c = sysId.Account__r.Name;
			}
		}
	}
}

@TestVisible
private static void createAccountRelationships(List<Opportunity> opps) {
	Set<Id> setEndUser = new Set<Id>();
	Set<Id> setAccountId = new Set<Id>();

	List<Opportunity> oppsForAARs = new List<Opportunity>();

	//Get Account and End User Ids
	for (Opportunity opp : opps) {
		if (opp.End_User__c != null && opp.AccountId != null && opp.Existing_Match__c == null) {
			setEndUser.add(opp.End_User__c);
			setAccountId.add(opp.AccountId);
			oppsForAARs.add(opp);
		}
	}

	//if there are opps that are capable of having an Account Account Relationship
	if (oppsForAARs.size() > 0) {
		List<Account_Account_Relationship__c> aarList = [
			SELECT Id, Account_1__c, Account_2__c
			FROM Account_Account_Relationship__c
			WHERE Account_1__c IN : setAccountId
			AND Account_2__c IN : setEndUser
			AND Role__c = 'End User'
		];

		Map<String, Account_Account_Relationship__c> combinationAAR = new Map<String, Account_Account_Relationship__c>();

		//Concatenate fields to create a unique key that can be found from the Opportunity
		if (aarList.size() > 0) {
			for (Account_Account_Relationship__c aar : aarList) {
				combinationAAR.put(aar.Account_1__c + '-' + aar.Account_2__c, aar);
			}
		}

		List<Account_Account_Relationship__c> aarsForInsert = new List<Account_Account_Relationship__c>();

		//Create Account Account relationships for each Opportunity
		//Each Opportunity should have 2 Account Account Relationships
		for (Opportunity opp : oppsForAARs) {
			//Find the End User Account Account Relationship
			Account_Account_Relationship__c endUserMatch = combinationAAR.get(opp.AccountId + '-' + opp.End_User__c);

			if (endUserMatch == null) {
				endUserMatch = new Account_Account_Relationship__c(
					Account_1__c = opp.AccountId,
					Account_2__c = opp.End_User__c,
					Role__c = 'End User'
					);
				aarsForInsert.add(endUserMatch);
				combinationAAR.put(endUserMatch.Account_1__c + '-' + endUserMatch.Account_2__c, endUserMatch);
			}
		}

		if (aarsForInsert.size() > 0) {
			insert aarsForInsert;
		}
	}
}

@TestVisible
private static void createProgramPartnerParty(List<Opportunity> opps) {

	Set<String> programs = new Set<String>();
	Set<Id> dealers = new Set<Id>();

	List<Opportunity> oppsToCreatePPs = new List<Opportunity>();

	//Get Vendor Programs, Dealer Ids, and Opportunities that have both
	for (Opportunity opp : opps) {
		if (opp.Program__c != null && opp.AccountId != null) {
			programs.add(opp.Program__c);
			dealers.add(opp.AccountId);
			oppsToCreatePPs.add(opp);
		}
	}

	if (oppsToCreatePPs.size() > 0) {
		List<Program_Partner_Party__c> pps = [
			SELECT Id, Name, Program__c, Dealer__c
			FROM Program_Partner_Party__c
			WHERE Program__c IN : programs
			AND Dealer__c IN : dealers
		];

		Map<String, Program_Partner_Party__c> combinationProgramParties = new Map<String, Program_Partner_Party__c>();

		//Concatenate fields to create a unique key that can be found from the Opportunity
		if (pps.size() > 0) {
			for (Program_Partner_Party__c ad : pps) {
				combinationProgramParties.put(ad.Program__c + '-' + ad.Dealer__c, ad);
			}
		}

		List<Program_Partner_Party__c> createPPs = new List<Program_Partner_Party__c>();

		//if an Program Party doesn't exist for an Opportunity, create one
		for (Opportunity opp : oppsToCreatePPs) {
			Program_Partner_Party__c ad = combinationProgramParties.get(opp.Program__c + '-' + opp.AccountId);
			if (ad == null) {
				Program_Partner_Party__c createPp = new Program_Partner_Party__c();
				createPp.Dealer__c = opp.AccountId;
				createPp.Program__c = opp.Program__c;
				createPPs.add(createPp);

				combinationProgramParties.put(createPp.Program__c + '-' + createPp.Dealer__c, createPp);
			}
		}

		if (createPPs.size() > 0) {
			insert createPPs;
		}
	}
}


// - Set Business Unit flags on Accounts based on the Opportunity's Business Unit
// - Create Account Business Unit Mapping records instead of updating the Account directly to avoid record locking
//   when running batches concurrently with Bulk API. The Updating of the actual Account records happens in a
//   Scheduled Batch Job (executed in PostTriggerBatchScheduler).
//UPDATED: 4-21-2020 By Newton Sun, Traction on demand
@TestVisible
private static void updateAccountBusinessFlags(List<Opportunity> opps) {
	Set<Id> accIds = new Set<Id>();
	List<Opportunity> oppsWAccountOrEU = new List<Opportunity>();
	List<Id> buId = new List<Id>();

	//Get Account Ids (AccountId and End_User__c)
	for (Opportunity opp : opps) {
		if (opp.End_User__c != null || opp.AccountId != null) {
			oppsWAccountOrEU.add(opp);
			if(opp.Business_Unit__c != null) {
				buId.add(opp.Business_Unit__c);
			}
			if (opp.End_User__c != null) {
				accIds.add(opp.End_User__c);
			}
			if (opp.AccountId != null) {
				accIds.add(opp.AccountId);
			}
		}
	}

	if (oppsWAccountOrEU.size() > 0) {
		//Get possible Accounts that might need updating
		Map<Id, Account> accById = new Map<Id, Account>([
									//PBI:446085:Account Business Unit Mapping: Golf and Turf:Added Golf_and_Turf__c in Query:Geetha
									SELECT Id, Technology_Solutions__c, Commercial_Finance__c, CleanTech__c, CT_and_I__c,
									Healthcare__c, Digital_Imaging__c, Food_and_Ag__c, Golf_and_Turf__c
									FROM Account
									WHERE Id IN: accIds
		                                                ]);

		//update to get business unit records as well
		Map<Id, Business_Unit__c> buById = new Map<Id, Business_Unit__c>([
											 SELECT Id, Business_Unit_Flag_API_Name__c
											 FROM Business_Unit__c
											 WHERE Id IN: buId
		                                                                 ]);

		Map<Id, Account_Business_Unit_Mapping__c> accBUByAccId = new Map<Id, Account_Business_Unit_Mapping__c>();
		for (Opportunity opp : oppsWAccountOrEU) {
			String buToCheck;
			Business_Unit__c bu = buById.get(opp.Business_Unit__c);

			if(bu != null) {

				buToCheck = bu.Business_Unit_Flag_API_Name__c;
			}
			if (opp.AccountId != null) {
				Account_Business_Unit_Mapping__c accBU = accBUByAccId.get(opp.AccountId);
				if (accBU == null) {
					accBU = new Account_Business_Unit_Mapping__c(Account__c = opp.AccountId);
				}
				Account acc = accById.get(opp.AccountId);
				if (acc != null) {
					//Set the Business Unit flags on the Account Business Unit Mapping record
					Account_Business_Unit_Mapping__c accBUUpdate = setAccountBusinessUnitFlags(buToCheck, acc, accBU);
					if (accBUUpdate != null) {
						accBUUpdate.Region_SFDC_ID__c = opp.Region_Relationship__c;
						accBUUpdate.Legal_Entity_Description__c = opp.Legal_Entity_Description__c;
						accBUUpdate.Region_Description__c = opp.Region_Description__c;
						//if a Business Unit flag was set, add to the map to update
						accBUByAccId.put(accBUUpdate.Account__c, accBUUpdate);
					}
				}
			}
			if (opp.End_User__c != null) {
				Account_Business_Unit_Mapping__c accBU = accBUByAccId.get(opp.End_User__c);
				if (accBU == null) {
					accBU = new Account_Business_Unit_Mapping__c(Account__c = opp.End_User__c);
				}
				Account acc = accById.get(opp.End_User__c);
				if (acc != null) {
					//Set the Business Unit flags on the Account Business Unit Mapping record
					Account_Business_Unit_Mapping__c accBUUpdate = setAccountBusinessUnitFlags(buToCheck, acc, accBU);
					if (accBUUpdate != null) {
						accBUUpdate.Region_SFDC_ID__c = opp.Region_Relationship__c;
						accBUUpdate.Legal_Entity_Description__c = opp.Legal_Entity_Description__c;
						accBUUpdate.Region_Description__c = opp.Region_Description__c;
						//if a Business Unit flag was set, add to the map to update
						accBUByAccId.put(accBUUpdate.Account__c, accBUUpdate);
					}
				}
			}
		}

		if (accBUByAccId.size() > 0) {
			//Insert the new Account Business Unit Mapping records, the batch job will update the associated
			//accounts then delete these records.
			insert accBUByAccId.values();
		}
	}
}

// - Help updateAccountBusinessFlags by determining which Business Unit flags to set based on the Opportunity
//   and Account
@TestVisible
private static Account_Business_Unit_Mapping__c setAccountBusinessUnitFlags(String buString, Account acc, Account_Business_Unit_Mapping__c accBU) {
	if (buString == 'Technology_Solutions__c' && !acc.Technology_Solutions__c) {
		accBU.Technology_Solutions__c = true;
	} else if (buString == 'Digital_Imaging__c' && !acc.Digital_Imaging__c) {
		accBU.Digital_Imaging__c = true;
	} else if (buString == 'CT_and_I__c' && !acc.CT_and_I__c) {
		accBU.CT_and_I__c = true;
	} else if (buString == 'Healthcare__c' && !acc.Healthcare__c) {
		accBU.Healthcare__c = true;
	} else if (buString == 'CleanTech__c' && !acc.CleanTech__c) {
		accBU.CleanTech__c = true;
	} else if (buString == 'Commercial_Finance__c' && !acc.Commercial_Finance__c) {
		accBU.Commercial_Finance__c = true;
	} else if (buString == 'Food_and_Ag__c' && !acc.Food_and_Ag__c) {
		accBU.Food_and_Ag__c = true;
		//PBI:446085:Account Business Unit Mapping: Golf and Turf:Added Golf_and_Turf__c to set true:Geetha
	} else if (buString == 'Golf_and_Turf__c' && !acc.Golf_and_Turf__c) {
		accBU.Golf_and_Turf__c = true;
	}
	return accBU;
}

// - Map the Business Unit to a Business Unit in Salesforce to clean the values
// PBI Number : 724685
// Description: Removed the hardcoding and used CustomMeta data values for mapping
// Date       : 25/04/2022
// Author     : Shoba Thummala
@TestVisible
private static void setBusinessUnit(List<Opportunity> opps) {
	List<String> listOfBU=New List<String>();
	map<string,string> mapOfBU=new map<string,string> ();
	Set<Id> oppProgramSet = new Set<Id>();                //724685
	for(Business_Unit_Association_Index__mdt objBUAI:[SELECT Id, Business_Unit_Attribute__c, Business_Unit_Name__c
	                                                  FROM Business_Unit_Association_Index__mdt ])
	{
		mapOfBU.put(objBUAI.Business_Unit_Attribute__c,objBUAI.Business_Unit_Name__c);
	}
	//Get Program's Business Unit to check and map with Metadata
	for(Opportunity opp :opps) {
		oppProgramSet.add(opp.program__c);
	}
	Map<Id, Program__c> mapOfProgramBU = new Map<Id, Program__c>([
									     SELECT Id, Business_Unit__c, Business_Unit__r.Name FROM Program__c
									     WHERE Id IN: oppProgramSet
	                                                             ]);

	for(Opportunity Opp:Opps) {
		String businessUnit;
		if(mapOfProgramBU.containsKey(Opp.program__c) && Opp.Source_System__c !='CDW_Canada' ) {                 //866653 - Added a check to bypass Canada Opportunity from copying Program BU to Opportunity BU
			businessUnit = mapOfBU.get(mapOfProgramBU.get(Opp.program__c).Business_Unit__r.Name);                //724685
		}else{
			businessUnit = mapOfBU.get(Opp.Business_Unit1__c);
		}
		if (businessUnit != null) {
			if (opp.Business_Unit1__c == 'Public Finance') {
				opp.Business_Segment__c = 'Public Finance';
			}
			opp.Business_Unit1__c = businessUnit;
		} else {
			opp.Business_Unit1__c = 'Other';
		}
		if(Opp.Source_System__c =='CDW_Canada') {                 //866653 - Update Business_Unit_Description__c for Sharing rules
			opp.Business_Unit_Description__c = opp.Business_Unit1__c;
		}
	}
}

// - if an Opportunity's Application Number ends in 'T' change the Type to 'Renewal'
// PBI:522080:Commenting this method as Opp type need not set to 'Renewal' anymore:Geetha
/*@TestVisible
   private static void setType(List<Opportunity> opps) {
     for (Opportunity opp : opps) {
         if (opp.Location__c == 'United States' && String.isNotBlank(opp.Application_Number__c) && opp.Application_Number__c.right(1) == 'T') {
             opp.Type = 'Renewal';
         }
         //PBI:428770:Opportunity Type should not be set to 'New' for all the Profile Users:GeethaBharadwaj-DLL
         /*else {
             opp.Type = 'New';
         }
     }
   }*/

// - Assign Opportunities to the Sales Rep from the Associated Sales Rep Id record
// - if there isn't a matching record, assign the Opportunity to Label.IntegrationUserId
@TestVisible
private static void setOwner(List<Opportunity> opps) {
	Set<String> repIds = new Set<String>();
	Set<String> repSourceSystems = new Set<String>();
	Set<ID> oldOwner = new Set<ID>();

	Map<ID,ID> oppOwnerMap = new Map<ID,ID>();



	for (Opportunity opp : opps) {
		if (String.isNotBlank(opp.Sales_Rep_ID__c) && String.isNotBlank(opp.Source_System__c)) {
			repIds.add(opp.Sales_Rep_ID__c);
			repSourceSystems.add(opp.Source_System__c);
		}
	}

	Map<String, Sales_Rep_ID__c> mapSalesRep = new Map<String, Sales_Rep_ID__c>();
	List<Sales_Rep_ID__c> salesRepIds = [
		SELECT Sales_Rep_ID__c, Sales_Rep__c, Sales_Rep__r.IsActive, Source_System__c
		FROM Sales_Rep_ID__c
		WHERE Sales_Rep_ID__c IN : repIds
		AND Source_System__c IN : repSourceSystems
		AND Sales_Rep__r.IsActive = TRUE
	];

	if (salesRepIds.size() > 0) {
		for (Sales_Rep_ID__c sRep : salesRepIds) {
			mapSalesRep.put(sRep.Sales_Rep_ID__c + '-' + sRep.Source_System__c, sRep);
		}

		for (Opportunity opp : opps) {
			Sales_Rep_ID__c sRep = mapSalesRep.get(opp.Sales_Rep_ID__c + '-' + opp.Source_System__c);
			if (sRep != null) {
				opp.OwnerId = sRep.Sales_Rep__c;
			} else {
				opp.OwnerId = Label.IntegrationUserID;
			}
		}
	} else {
		for (Opportunity opp : opps) {
			opp.OwnerId = Label.IntegrationUserID;
		}
	}




}

// - Map the Stage to a Stage in Salesforce to clean the values
/* PBI855444 : Commenting this method as Stage translation is now happening in Azure, not in Salesforce
   @TestVisible
   private static void setStage(List<Opportunity> opps) {

        Map<String, Sub_Stage_Mapping__mdt> stageMap = new Map<String, Sub_Stage_Mapping__mdt>();
        for (Sub_Stage_Mapping__mdt sn : [SELECT Key__c, Value__c,Global_Stage_Value__c FROM Sub_Stage_Mapping__mdt]) {
                String key = String.isBlank(sn.Key__c) ? sn.Key__c : sn.Key__c.toUpperCase();
                stageMap.put(key, sn);
        }

        for (Opportunity opp : opps) {
                String mappedStage = String.isBlank(opp.Sub_Stage__c) ? null :(stageMap.containsKey(opp.Sub_Stage__c.toUpperCase()) ? stageMap.get(opp.Sub_Stage__c.toUpperCase()).value__c: null);

                if (mappedStage == null) {
                        opp.StageName = stageMap.get(null).Global_Stage_Value__c;
                        opp.Sub_Stage__c = stageMap.get(null).Value__c;
                } else {
                        opp.StageName = stageMap.get(opp.Sub_Stage__c.toUpperCase()).Global_Stage_Value__c;
                        opp.Sub_Stage__c = mappedStage;
                }
        }
   }
 */
// - if the Stage set to approved and pending when current stage is Docs Out, Docs Back, PO Sent; set to priorvalue
/* PBI855444 : Commenting this method as Stage translation is now happening in Azure, not in Salesforce
   @TestVisible
   private static void updateStage(Map<Id, Opportunity> oldOppMap, Map<Id, Opportunity> newOppMap) {

        Map<String, Sub_Stage_Mapping__mdt> stageMap = new Map<String, Sub_Stage_Mapping__mdt>();
        for (Sub_Stage_Mapping__mdt sn : [SELECT Key__c, Value__c,Global_Stage_Value__c,Override_User_Managed_Values__c FROM Sub_Stage_Mapping__mdt]) {
                String key = String.isBlank(sn.Key__c) ? sn.Key__c : sn.Key__c.toUpperCase();
                stageMap.put(key, sn);
        }

        for (Opportunity oldOpp : oldOppMap.values()) {
                Opportunity newOpp = newOppMap.get(oldOpp.Id);
                //if(newOpp.User_Managed_Opportunity__c){
                if(newOpp.User_Managed_Opportunity__c && (newOpp.StageName == newOpp.Sub_Stage__c)) {

                        Boolean opp_Value_Override = false;

                        if(stageMap.containsKey(newOpp.Sub_Stage__c == null ? newOpp.Sub_Stage__c : newOpp.Sub_Stage__c.toUpperCase())) {
                                opp_Value_Override = stageMap.get(newOpp.Sub_Stage__c == null ? newOpp.Sub_Stage__c : newOpp.Sub_Stage__c.toUpperCase()).Override_User_Managed_Values__c;
                        }
                        if(opp_Value_Override) {
                                updateStage(stageMap,oldOpp,newOpp);
                        }else{
                                newOpp.Sub_Stage__c = oldOpp.Sub_Stage__c;
                                newOpp.StageName = oldOpp.stageName;
                        }

                }else{
                        updateStage(stageMap,oldOpp,newOpp);
                }
        }
   }
 */
/* PBI855444 : Commenting this method as Stage translation is now happening in Azure, not in Salesforce
   @TestVisible
   private static void updateStage(Map<String, Sub_Stage_Mapping__mdt> stageMap,Opportunity oldOpp, Opportunity newOpp){
        String mappedStage = String.isBlank(newOpp.Sub_Stage__c) ? null :(stageMap.containsKey(newOpp.Sub_Stage__c.toUpperCase()) ? stageMap.get(newOpp.Sub_Stage__c.toUpperCase()).value__c: null);
        // if (mappedStage == null && ((oldOpp.Sub_Stage__c != newOpp.sub_Stage__c && newOpp.sub_Stage__c != null)||(oldOpp.StageName != newOpp.StageName && newOpp.StageName != null))) {
        if(mappedStage == null && (newOpp.StageName == newOpp.Sub_Stage__c)) {
                newOpp.StageName = stageMap.get(null).Global_Stage_Value__c;
                newOpp.Sub_Stage__c = stageMap.get(null).value__c;
                //PBI:432702:Integration Failures - Unprocessed Stage + Sub-Stage Values:Below code modified by Geetha Bharadwaj - DLL
                // } else if((oldOpp.Sub_Stage__c != newOpp.sub_Stage__c && newOpp.sub_Stage__c != null)||(oldOpp.StageName != newOpp.StageName && newOpp.StageName != null)) {
        } else if(mappedStage!=null && newOpp.sub_Stage__c != null && newOpp.StageName != null) {
                newOpp.StageName = stageMap.get(newOpp.Sub_Stage__c.toUpperCase()).Global_Stage_Value__c;
                newOpp.Sub_Stage__c = mappedStage;
                //PBI:534141:Setting Opp Forecast Category from Sub-Stage (Overriding default category for Docs Out to Best Case
                if (newOpp.Sub_Stage__c=='Documents Out') {
                        newOpp.ForecastCategoryName = 'Best Case';
                }
        }
   }
 */
// - if the Business Unit changed, revert to the old Business Unit
@TestVisible
private static void revertBusinessUnit(Map<Id, Opportunity> oldOppMap, Map<Id, Opportunity> newOppMap) {
	for (Opportunity oldOpp : oldOppMap.values()) {
		Opportunity newOpp = newOppMap.get(oldOpp.Id);

		if (oldOpp.Business_Unit1__c != newOpp.Business_Unit1__c) {
			newOpp.Business_Unit1__c = oldOpp.Business_Unit1__c;
		}
	}
}

//Update Opportunity Relationship records
@TestVisible
private static void updateOpportunityRelationships(List<Opportunity> opps) {

	//Create list of all existing Opp Relationships
	List<Opportunity_Relationship__c> opprel = [
		SELECT Id, Opportunity__c, Account__c, Opportunity_Role__c
		FROM Opportunity_Relationship__c
		WHERE Opportunity__c IN : opps
	];

	Map<String, Opportunity_Relationship__c> combinationOppRel = new Map<String, Opportunity_Relationship__c>();

	//Create unique key for Opp relationship records
	if (opprel.size() > 0) {
		for (Opportunity_Relationship__c rels : opprel) {
			combinationOppRel.put(rels.Opportunity__c + '-' + rels.Opportunity_Role__c, rels);
		}
	}

	List<Opportunity_Relationship__c> opprelInsert = new List<Opportunity_Relationship__c>();
	List<Opportunity_Relationship__c> opprelUpdate = new List<Opportunity_Relationship__c>();
	List<Opportunity_Relationship__c> opprelDelete = new List<Opportunity_Relationship__c>();
	//if Opportunity Relationship doesn't exist, create one else update existing
	for (Opportunity opp : opps) {
		//Find End User Opportunity Relationship
		Opportunity_Relationship__c endusermatch = combinationOppRel.get(opp.Id + '-End User');
		//Find Vendor Opportunity Relationship
		Opportunity_Relationship__c vendormatch = combinationOppRel.get(opp.Id + '-Vendor');

		//if Opp Rel for End User and Vendor is not found; create new
		if (endusermatch == null && vendormatch == null) {
			if (opp.End_User__c != null) {
				endusermatch = new Opportunity_Relationship__c(
					Account__c = opp.End_User__c,
					Opportunity__c = opp.Id,
					Opportunity_Role__c = 'End User',
					CurrencyIsoCode = opp.CurrencyIsoCode
					);
				opprelInsert.add(endusermatch);
				combinationOppRel.put(endusermatch.Opportunity__c + '-' + endusermatch.Opportunity_Role__c, endusermatch);
			}

			if (opp.AccountId != null) {
				vendormatch = new Opportunity_Relationship__c(
					Account__c = opp.AccountId,
					Opportunity__c = opp.Id,
					Opportunity_Role__c = 'Vendor',
					CurrencyIsoCode = opp.CurrencyIsoCode
					);
				opprelInsert.add(vendormatch);
				combinationOppRel.put(vendormatch.Opportunity__c + '-' + vendormatch.Opportunity_Role__c, endusermatch);
			}
		}
		//if vendor Opp Rel is not found but end user Opp rel is found; create new Vendor Opp rel and update/delete End User Opp rel
		else if (endusermatch != null && vendormatch == null) {
			if (opp.AccountId != null) {
				vendormatch = new Opportunity_Relationship__c(
					Account__c = opp.AccountId,
					Opportunity__c = opp.Id,
					Opportunity_Role__c = 'Vendor',
					CurrencyIsoCode = opp.CurrencyIsoCode
					);
				opprelInsert.add(vendormatch);
				combinationOppRel.put(vendormatch.Opportunity__c + '-' + vendormatch.Opportunity_Role__c, vendormatch);
			}
			if (endusermatch.Account__c != opp.End_User__c) {
				//PBI:667166:Hotfix:Opportunity Trigger error
				if (opp.End_User__c == null && vendormatch != null) {
					opprelDelete.add(vendormatch);
				} else {
					endusermatch.Account__c = opp.End_User__c;
					opprelUpdate.add(endusermatch);
				}
			}
		}
		//if End User Opp Rel is not found but Vendor Opp rel is found; create new End User Opp rel and update/delete Vendor Opp rel
		else if (endusermatch == null && vendormatch != null) {
			if (opp.End_User__c != null) {
				endusermatch = new Opportunity_Relationship__c(
					Account__c = opp.End_User__c,
					Opportunity__c = opp.Id,
					Opportunity_Role__c = 'End User',
					CurrencyIsoCode = opp.CurrencyIsoCode
					);
				opprelInsert.add(endusermatch);
				combinationOppRel.put(endusermatch.Opportunity__c + '-' + endusermatch.Opportunity_Role__c, endusermatch);
			}
			if (vendormatch.Account__c != opp.AccountId) {
				//PBI:667166:Hotfix:Opportunity Trigger error
				if (opp.AccountId == null && vendormatch != null) {
					opprelDelete.add(vendormatch);
				}else {
					vendormatch.Account__c = opp.AccountId;
					opprelUpdate.add(vendormatch);
				}
			}
		}
		//if Vendor and End User opp rel found; update/delete both opp rel records
		else if (endusermatch != null && vendormatch != null) {
			if (endusermatch.Account__c != opp.End_User__c) {
				//PBI:667166:Hotfix:Opportunity Trigger error
				if (opp.End_User__c == null && endusermatch != null) {
					opprelDelete.add(endusermatch);
				} else {
					endusermatch.Account__c = opp.End_User__c;
					opprelUpdate.add(endusermatch);
				}
			}
			if (vendormatch.Account__c != opp.AccountId) {
				//PBI:667166:Hotfix:Opportunity Trigger error
				if (opp.AccountId == null && vendormatch != null) {
					opprelDelete.add(vendormatch);
				} else {
					vendormatch.Account__c = opp.AccountId;
					opprelUpdate.add(vendormatch);
				}
			}
		}

	}
	if (opprelInsert.size() > 0) {
		insert opprelInsert;
	}
	if (opprelUpdate.size() > 0) {
		update opprelUpdate;
	}
	if (opprelDelete.size() > 0) {
		delete opprelDelete;
	}
}
}