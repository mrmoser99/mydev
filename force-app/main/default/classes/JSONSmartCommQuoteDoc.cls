public class JSONSmartCommQuoteDoc {


public class Forms {
public List<MultiForms> MultiForms;
}

public Request Request;

public class Address {
public String AttentionLine;
public String Line1;
public String Line2;
public String Line3;
public String Line4;
public String City;
public String State;
public String Zip;
public String County;
public String Country;
public String FullAddress;
}

public class Recipients {
public String RecipientType;
public String RecipientName;
public Address Address;
}

public class MultiAddOns {
public String RelatedAsset;
public String Accessory;
public Double AccUnitPrice;
public String AccRateType;
}

public class QuoteHdr {
public String QuoteNo;
public String QuoteName;
public String QuoteType;
public String QuoteReason;
public String QuoteDate;
public String QuoteExpiry;
public String ProposalType;
}

public class Names {
public List<MultiNames> MultiNames;
}

public class Party {
public List<MultiParty> MultiParty;
}

public class Phones {
public List<MultiPhones> MultiPhones;
}

public class Assets {
public List<MultiAssets> MultiAssets;
}

public class RequestData {
public QuoteHdr QuoteHdr;
public QuoteLines QuoteLines;
public Party Party;
public Comments Comments;
}

public class PaymentSchedules_Z {
public List<MultiPymntSched_Z> MultiPymntSched;
}

public class MultiAssets {
public String AssetNo;
public String AssetDescription;
public String AssetType;
public String MasterAssetType;
public String Make;
public String Model;
public String SerialNumber;
public String Condition;
public Integer Quantity;
public Double UnitCost;
public Double MSRPAmount;
public String SalesTaxStatus;
public AddOns AddOns;
public Locations Locations;
public AssetAttributes AssetAttributes;
public PaymentSchedules_Z PaymentSchedules;
}

public class MultiURLs {
public String URLType;
public String URLAddress;
}

public class MultiFees {
public String Type;
public String Label;
public String Description;
public String Value;
}

public class MultiAssets_Z {
public String AssetNo;
public String AssetDescription;
public String AssetType;
public String MasterAssetType;
public String Make;
public String Model;
public String SerialNumber;
public String Condition;
public Integer Quantity;
public Double UnitCost;
public Double MSRPAmount;
public String SalesTaxStatus;
public AddOns AddOns;
public Locations Locations;
public AssetAttributes AssetAttributes;
}

public class MultiPhones {
public String PhoneType;
public String PhoneNumber;
}

public class PaymentSchedules {
public List<MultiPymntSched> MultiPymntSched;
}

public class Assets_Z {
public List<MultiAssets_Z> MultiAssets;
}

public class FinancialAttributes {
public String Term;
public String PurchaseOption;
public String PurchaseOptionType;
public Double PurchaseOptionValue;
public String PaymentOption;
public String PaymentFrequency;
public String BrokerPoints;
public String RateType;
public Double InterestRate;
public Integer NoAdvPayments;
public String PromoDaysToPurchase;
public Double SoftCostsPct;
public Double BookedResidualAmt;
public Double BilledResidualAmt;
public Double TradeUpAmount;
public PaymentSchedules PaymentSchedules;
public Fees Fees;
public Deductions Deductions;
}

public class URLs {
public List<MultiURLs> MultiURLs;
}

public class MultiLocations {
public String LocationID;
public String SiteNumber;
public String LocationUsage;
public Address Address;
}

public class Comments {
public List<MultiFees> MultiComments;
}

public class Locations {
public List<MultiLocations> MultiLocations;
}

public class Request {
public RequestDetails RequestDetails;
public RequestData RequestData;
}

public class AddOns {
public List<MultiAddOns> MultiAddOns;
}

public class Fees {
public List<MultiFees> MultiFees;
}

public class AssetAttributes {
public List<MultiFees> MultiAssetAttr;
}

public class RequestDetails {
public String SourceApplication;
public String GenDate;
public String DistributionMethod;
public String DocGenType;
public Integer NoOfCopies;
public Recipients Recipients;
public Forms Forms;
}

public class QuoteLines {
public List<MultiQuoteLines> MultiQuoteLines;
}

public class Deductions {
public List<MultiFees> MultiDeductions;
}

public class MultiNames {
public String NameType;
public String Title;
public String FirstName;
public String MiddleName;
public String LastName;
public String Suffix;
public String FullName;
}

public class MultiForms {
public Integer SeqNo;
public String ComplexParm;
public String DocTemplateCode;
public String DocTemplateName;
public String DocName;
public String Base64ContentPDF;
public String DocType;
}

public class MultiPymntSched {
public Integer NumberPayments;
public Double PreTaxPaymentAmount;
public Double StreamSalesTax;
public Double TotalPaymentAmount;
}

public class MultiParty {
public String PartyType;
public String PartyIdentifier;
public String AccountNumber;
public String CodeLogo;
public Names Names;
public Phones Phones;
public Locations Locations;
public URLs URLs;
}

public class MultiQuoteLines {
public String Option;
public FinancialAttributes FinancialAttributes;
public Assets Assets;
}

public class MultiPymntSched_Z {
public Integer NumberPayments;
public String StreamName;
public Double PreTaxPaymentAmount;
public Double StreamSalesTax;
public Double TotalPaymentAmount;
}

public static void testRun(){
	Integer i = 0;
	i++;

}

}