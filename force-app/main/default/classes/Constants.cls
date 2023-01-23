/**
* Name: Constants  
* Purpose: This Class is used for declare Constant value through out the application.
* 
* Version 1.0 @author Neha Bansal @date 2021-09-10 
* 
*/ 
public with sharing class Constants {

    public static final String SMARTCOMM_CONTRACT_SUB_DOC = 'AML-1;Contract-2;Purchase Option-3;Terms & Conditions-4;Insurance-5';
    public static final String SMARTCOMM_TEMPLATE = '990321633';
    public static final String SMARTCOMM_AML_TEMPLATE = '990319356';
    public static final String SMARTCOMM_AOD_TEMPLATE = '990322138';
    public static final String SMARTCOMM_PG_TEMPLATE = '990322324';
    public static final String SMARTCOMM_PURCHASEOPTION_TEMPLATE = '990369030';
    
    public static final String SMARTCOMM_DOCTYPE_AML = 'AML';
    public static final String SMARTCOMM_DOCTYPE_TERMANDCONDITION = 'Terms & Conditions'; 
    public static final String SMARTCOMM_DOCTYPE_PURCHASE_OPTION = 'Purchase Option';
    public static final String SMARTCOMM_DOCTYPE_INSURANCE = 'Insurance';
    public static final String SMARTCOMM_DOCTYPE_CONTRACT = 'Contract';
    public static final String SMARTCOMM_DOCTYPE_AOD = 'AOD';
    public static final String SMARTCOMM_DOCTYPE_PG = 'Payment Guarantor';
    public static final String PG_DOCTYPE_DCV = 'Guarantee Customer';
    
     public static final String SMARTCOMM_DOC_SUCCESS = 'Documents Generated';
     public static final String SMARTCOMM_DOC_FAIL = 'Failed';
    
     
    public static final String SPECIALCHAR1 = label.Special_Character1;
    public static final String SPECIALCHAR2 = label.Special_Character2;
    
    // Profile Name
    public static final String NORDICS_PROFILE_NAME = 'Nordics Community Profile';
    public static final String NORDICS_INTERNAL_DLL_MEMBER = 'Nordics Internal MVP';
    public static final String SYSTEM_ADMIN_PROFILE_NAME = 'System Administrator';
    public static final String LIFE_PROFILE = 'LIFE Profile';
    public static final String 	GLOBAL_BUSINESS_ADMINISTRATION = 'Global Business Administration';
    
    // Record types for Account object   
    public static final String VENDOR_ACCOUNT_RECORDTYPE_DEVELOPER_NAME = 'Vendor';
    public static final String END_USER_RECORD_TYPE_NAME = 'End_User';
    
    // Contact roles
    public static final string ULTIMATE_BENEFICIAL_OWNER_CONTACT_ROLE = 'Ultimate Beneficial Owner';
    public static final string LEASE_SIGNER_CONTACT_ROLE = 'Lease Signer';
    public static final string PRIMARY_CONTACT_ROLE = 'Primary Contact';

    // Record types for Opportunity object
    public static final String RETAIL_OPPORTUNITY_RECORDTYPE_DEVELOPER_NAME = 'Retail';
    
    //Custom Error Message for Submit Application
    public static final String ERROR_MESSAGE = label.Missing_field_in_SubmitApp_Error_message;

    // Record types for Error Log object
    public static final String GENERIC_ERRORLOG_RECORDTYPE = 'Generic';
    public static final String INTEGRATION_ERRORLOG_RECORDTYPE = 'Integration';
    
    // Quote statuses
    public static final String QUOTE_CALCULATION_STATUS = 'Calculation';
    public static final String QUOTE_CALCULATION_EXPIRED_STATUS = 'Calculation Expired'; 
    public static final String QUOTE_ASSESSMENT_STATUS = 'Assessment';
    public static final String QUOTE_APPROVED_STATUS = 'Approved';
    public static final String QUOTE_APPROVED_WITH_CON_STATUS = 'Approved With Conditions';
    public static final String QUOTE_REFER_STATUS = 'Refer'; 
    public static final String QUOTE_DOCUMENT_GEN_STATUS = 'Documents Generated';
    public static final String QUOTE_PENDING_DOCUMENT_STATUS = 'Pending Documentation';
    public static final String QUOTE_PENDINGESIGN_STATUS = 'Pending E-Sign';
    public static final String QUOTE_REVIEWCOMPLETED_STATUS = 'Review Completed';
    public static final String QUOTE_PENDING_VALIDATION_STATUS = 'Pending Validation';
    public static final String QUOTE_PENDING_INFO_STATUS = 'Pending Information';
    public static final String QUOTE_PENDING_REVIEW_STATUS = 'Pending Review';
    public static final String QUOTE_BLOCKED_DUE_TO_MULTIPLE_PG_STATUS = 'Blocked Due To Multiple PG';

    //Invoice types
    public static final string EDI = 'EDI';
    public static final string PDF = 'PDF';
    public static final string LETTER = 'Letter';

    // E-Sign Information statuses
    public static final string NEW_STATUS = 'New';
    public static final string PENDING_CONTRACT_STATUS = 'Pending_Contract';
    public static final string ACTIVE_STATUS = 'Active';
    public static final string CANCELLED_STATUS = 'CancelledByMerchant';
    public static final string COMPLETE_STATUS = 'Complete';
    public static final string EXPIRED_STATUS = 'Expired';
    public static final string FAILED_STATUS = 'Failed';
    public static final string REJECTED_STATUS = 'RejectedBySigner';
    public static final string PENDING_E_SIGN_STATUS = 'Pending E-Sign';
    
    //ITAD Types
    public static final string DATA_WIPING = 'Data Wiping';
    public static final string REVERSED_LOGISTICS = 'Reversed Logistics';
    public static final string ONSITE_PACKAGING = 'Onsite Packaging';

    // Product types
    public static final String SOFT_COST_PRODUCT_TYPE = 'Soft Cost';
    public static final String ASSET_HARD_PRODUCT_TYPE = 'Asset Hard';
    public static final String ASSET_SOFT_PRODUCT_TYPE = 'Asset Soft';
    public static final String ITAD_PRODUCT_TYPE = 'ITAD';
    public static final String MAINTENANCE_PRODUCT_TYPE = 'Maintenance';
    public static final String INSTALLATION_PRODUCT_TYPE = 'Installation';
    public static final String LICENCE_PRODUCT_TYPE = 'Licence';
    
    // Payment frequencies
    public static final String MONTHLY_PAYMENT_FREQUENCY = 'monthly';
    public static final String QUARTERLY_PAYMENT_FREQUENCY = 'quarterly';
    public static final String SEMI_ANNUALLY_PAYMENT_FREQUENCY = 'semi-annually';
    public static final String ANNUALLY_PAYMENT_FREQUENCY = 'annually';
    
    
     // Payment frequencies for Quote
    public static final String QT_MONTHLY_PAYMENT_FREQUENCY = 'Monthly';
    public static final String QT_QUARTERLY_PAYMENT_FREQUENCY = 'Quarterly';
    public static final String QT_SEMI_ANNUALLY_PAYMENT_FREQUENCY = 'Semi-Annually';
    public static final String QT_ANNUALLY_PAYMENT_FREQUENCY = 'Annually';
    
  
    // Rate Type
    public static final String VARIABLE_RATE_TYPE = 'Variable';
    public static final String FIXED_RATE_TYPE = 'Fixed';
    public static final string STR_RATE_VALUE = 'Fixed;Variable';
  
    // Constants for Asset Model Web Service
    public static final String SALE_PRICE = 'sale-price';
    public static final String LIST_PRICE = 'list-price';
    
    // Constants for AzureADB2CCustomAuth
    public static final String CUSTOM_METADATA_TYPE = 'Standard_Auth_Credentials__mdt';
    public static final String AUTH_PROVIDER_NAME = 'Azure_AD_B2C';
    public static final string FORGOTPASSWORD_ERRORCODE = 'AADB2C90088';
    
    // Constants for Calculation Request Body Wrapper
    public static final String CALCULATE_PAYMENTS = 'payments';    
    
    // Dummy maintenance product for Calculation API and Offer Web Service
    public static final String DUMMY_MAINTENANCE_PRODUCT = 'No Maintenance Dummy Product';

    // Constants for Document types
    public static final String SDO_DOCUMENT_TYPE = 'SDO';
    public static final String PAdES_DOCUMENT_TYPE = 'PAdES';
    public static final string AOD_DOCUMENT_TYPE = 'AOD';
    public static final string CONTRACT_DOCUMENT_TYPE = 'Contract';
    public static final string SIGNED_DOCUMENT_TYPE = 'Signed';
     public static final string UNSIGNED_DOCUMENT_TYPE = 'Unsigned';

    // Constants for Account team member roles
    public static final String ACCOUNT_MANAGER_ROLE = 'Account Manager';

    // Constants for Insurance options
    public static final String INCLUDED_IN_RENT = 'Included in rent';
    public static final String ADDED_ON_INVOICE = 'Added on invoice';
    public static final String DISPLAYED_SEPARATLY = 'Displayed separately';

    // Constants for Callout names
    public static final String SUBMIT_APPLICATION = 'Submit_Application';
    public static final String CREDIT_ASSESSMENT = 'Credit_Assessment';
    public static final String SEARCH_PARTY = 'SearchParty';
    public static final String CALCULATION = 'calculation';
    public static final String CREATE_ORDER = 'Create_Order';
    public static final String CANCEL_ORDER = 'Cancel_Order';
    public static final String GET_SDO = 'Get_SDO';
    public static final String SEND_CODE = 'Send_Code';
    public static final String SEND_DOCUMENTS = 'Send_Documents';
    public static final String SMART_COMM_DOC = 'Smart_Comm_Doc';
    public static final String AZURE = 'azure';
    public static final String AXWAY = 'axway';
    public static final String SUBMITAPPLICATION = 'submitApplication';
    public static final String CREDITASSESSMENT = 'creditAssessment';
    public static final String OPPTY_DEFAULT_STAGE ='Quoting';
    
    // Constants for Error Logger Class
    public static final String  QUERY_LIMIT= '1. SOQL Queries used / SOQL Queries allowed: ';
    public static final String  DML_LIMIT= '2. Number of records queried so far /  Number allowed: ';
    public static final String  DML_STAT= '3. Number of DML statements used so far / Number allowed: ';
    public static final String  CPU_TIME= '4. Amount of CPU time (in ms) used so far / CPU usage time (in ms) allowed: ';

    // Currency codes
    public static final String  USD_CURRENCY = 'USD';
    
    // Document Response and Question type 
    public static final String  DOC_YES = 'Yes';
    public static final String  DOC_NO = 'No';
    public static final String  DOC_NA = 'N/A';
    public static final String  QUESTION_WET_CONTRACT = 'Contract certified as complete';
    
    // Nordics Email Controller
    public static final String SEN1 = System.Label.The_credit_is_approved_with_guarantee_by;
    public static final String SEN2 = System.Label.with_personal_number;
    public static final String SEN3 = System.Label.Amount;
    public static final String SEN4 = System.Label.Current_Currency;
    public static final String SEN5 = System.Label.with_organisation_number;
    public static final String SEN6 = System.Label.Credit_is_approved_with;
    public static final String SEN7 = System.Label.Credit_is_approved_with_a_maximum_duration_of;
    public static final String SEN8 = System.Label.months;
    public static final String COMPANY = 'Company';
    
     // Constants for Unsigned Doc Stauts
    public static final String  UNSIGNED_STATUS_SENT = 'Sent';
    public static final String  UNSIGNED_STATUS_FAIL = 'Failed';
    
      // Constants for Deemed_AOD type SpeTnC
    public static final String  SPETNC_TYPE = 'Deemed_AOD';
    
    
    // Constants for RV Type on Offer
    public static final String  PURCHASE_OPTION_RV = 'Purchase Option';
    public static final String  DLL_3RDPARTY_RV = 'DLL or 3rd Party';
    public static final String  NO_RV = 'None';
    
    // Constants for Lacs Error message
    public static final String  RESIDUAL_VALUE = 'Residual value';
    public static final String  INSURANCE = 'Insurance';
   
}