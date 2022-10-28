/**
 * Class creates the JSON response of the Calculation API.
 * @author Anujit (Cognizant)
 * @date 2021-01-10
 */
public with sharing class CalculationResponseBodyWrapper extends BaseResponseBodyWrapper {
    
    public CalculationResponseFinanceInput financeInput = new CalculationResponseFinanceInput();
    public CalculationResponseFinanceCalculation financeCalculation = new CalculationResponseFinanceCalculation();
    public CalculationResponsePaymentCalculation paymentCalculation;
    public List<ConsolidatedScheduledPayment> consolidatedPayments;
    public List<CalculationCommission> commissions;
    public SubsidyPayment subsidies;
    public List<ScheduledPayment> payments;
    public List<CalculationPerAssetResponse> assetCalculations;

    public class CalculationResponseFinanceInput {

        public String calculate;
        public CalculationFinanceStructureResponse financeStructure = new CalculationFinanceStructureResponse();
        public List<CalculationFee> fees;
        public List<CalculationInsuranceResponse> insurances;
        public List<CalculationMaintenance> maintenance;
        public List<CalculationAssetResponse> assets;
    }

    public class CalculationFinanceStructureResponse {

        public Integer numberOfMonths;
        public Integer numberOfPayments;
        public Date startDate;
        public Date endDate;
        public List<DelayPayment> delayPayment;
        public Integer terminalPauseRegularPayments;
        public String paymentFrequency;
        public String paymentTiming;
        public String paymentMethod;
        public Integer delayVatPayment;
        public CalculationFinance finance = new CalculationFinance();
    }

    public class DelayPayment {

        public String type;
        public Integer initialPause;
        public String initialPauseUnit;
        public Date startDate;
    }

    public class CalculationFinance {

        public Double financeAmount;
        public Integer initialPaymentMultiplier;
        public Decimal initialPaymentAmount;
        public Decimal balloon;
        public CalculationNetDeposit netDeposit;
        public CalculationPayments payments = new CalculationPayments();
        public CalculationRates rates;
        public CalculationPaymentProfile paymentProfile;
        public List<CalculationCommission> commissions;
        public List<CalculationSubsidyResponse> subsidies;
    }

    public class CalculationNetDeposit {

        public Double amount;
        public Double downPayment;
        public Double settlement;
        public Double tradeIn;
    }

    public class CalculationPayments {

        public List<CalculationCustomPayment> custom;
        public List<CalculationConsolidatedPayment> consolidated = new List<CalculationConsolidatedPayment>();
    }

    public class CalculationCustomPayment {

        public Date paymentDate;
        public String type;
        public Double amount;
        public Integer multiplier;
        public Double percentage;
        public String percentageOf;
    }

    public class CalculationConsolidatedPayment {

        public Date startDate;
        public String type;
        public Integer numberOfPayments;
        public Double amount;
    }

    public class CalculationRates {

        public Double effectiveCustomerRate;
        public String calculate;
    }

    public class CalculationPaymentProfile {

        public String type;
        public String id;
    }

    public class CalculationCommission {

        public Double amount;
        public String id;
    }

    public class CalculationSubsidyResponse {

        public String type;
        public Double amount;
        public String id;
    }

    public class CalculationFee {

        public Double amount;
        public String id;
    }

    public class CalculationInsuranceResponse {

        public Double amount;
        public Double insuranceTaxPercentage;
        public String id;
    }

    public class CalculationMaintenance {

        public Double amount;
        public String id;
    }

    public class CalculationAssetResponse {

        public AssetModelIdentifier modelIdentifier;
        public Integer quantity;
        public Double salePrice;
        public Double listPrice;
        public Double vatPercentage;
        public Double vatAmount;
        public String condition;
        public Integer yearOfManufacturing;
        public Boolean subLeased;
        public Integer meterRead;
        public Integer usageUnitsPerPeriod;
        public String usageEnvironment;
        public CalculationResidualValue residualValue;
        public CalculationRepurchaseAmount repurchaseAmount;
        public Double excessiveUsageLimit;
        public Double excessiveUsagePenaltyAmount;
        public List<CalculationFee> fees;
        public List<CalculationSubsidyResponse> subsidies;
        public List<CalculationAssetInsuranceResponse> insurances;
        public List<CalculationMaintenance> maintenance;
    }
    
     public class CalculationPerAssetResponse {

        public AssetModelIdentifier modelIdentifier;
        public Boolean minimumRegularPaymentAmount;
        public Integer quantity;
        public Double salePrice;
        public CalculationResidualValue residualValue;
        public List<CalculationAssetInsuranceResponse> insurances;
        public Double vatAmount;
        public CalculationResponseFinanceCalculation financeCalculation;
		public List<ConsolidatedScheduledPayment> consolidatedPayments;
    }
    
    public class AssetModelIdentifier {
        
        public String masterAssetTypeName;
        public String categoryName;
        public String typeName;
        public String brandName;
        public String modelName;
    }

    public class CalculationResidualValue {

        public Double value;
        public String id;
    }

    public class CalculationRepurchaseAmount {

        public Double amount;
        public String id;
    }

    public class CalculationAssetInsuranceResponse {

        public Double amount;
        public Double insuranceTaxPercentage;
        public Boolean replacement;
        public Double excessAmount;
        public String id;
    }

    public class CalculationResponseFinanceCalculation {

        public Double financeAmount;
        public Double financeDeviation;
        public Double netPresentValue;
        public Double futureValue;
        public CalculationResponseRate rates = new CalculationResponseRate();
    }

    public class CalculationResponseRate {

        public Double nominalInterestRate;
        public Double nominalCustomerRate;
        public Double effectiveInterestRate;
        public Double effectiveCustomerRate;
        public Double effectiveCustomerRateIncludingFees;
        public String compoundingFrequency;
    }

    public class CalculationResponsePaymentCalculation {

        public CalculationResponseRentalPayments rentalPayments;
        public CalculationResponseFee fees;
        public CalculationResponseMaintenance maintenance;
        public CalculationResponseInsurance insurances;
        public CalculationResponseVatPayments vatPayments;
    }

    public class CalculationResponseRentalPayments {

        public Double amount;
        public Double principal;
        public Double interestAmount;
    }

    public class CalculationResponseFee {

        public Double amount;
    }

    public class CalculationResponseMaintenance {

        public Double amount;
    }

    public class CalculationResponseInsurance {

        public Double amount;
    }

    public class CalculationResponseVatPayments {

        public Double amount;
    }

    public class ConsolidatedScheduledPayment {

        public Integer numberOfPayments;
        public Double amount;
        public String type;
        public Date startDate;
        public Integer monthStart;
    }

    public class SubsidyPayment {

        public String type;
        public Double amount;
        public String id;
        public AssetModelIdentifier assetModelIdentifier;
    }

    public class ScheduledPayment {

        public Date paymentDate;
        public Double balanceOutstanding;
        public RentalPayment rentalPayment;
        public VatPayment vatPayment;
        public List<FeePayment> fees;
        public List<InsurancePayment> insurances;
        public List<MaintenancePayment> maintenance;
    }

    public class RentalPayment {

        public Double amount;
        public Double principal;
        public Double interestAmount;
    }

    public class VatPayment {

        public Double amount;
    }

    public class FeePayment {

        public Double amount;
        public Double vatAmount;
        public String id;
        public AssetModelIdentifier assetModelIdentifier;
    }

    public class InsurancePayment {

        public Double amount;
        public Double vatAmount;
        public Double insuranceTaxAmount;
        public String id;
        public 	AssetModelIdentifier assetModelIdentifier;
    }

    public class MaintenancePayment {

        public Double amount;
        public Double vatAmount;
        public String id;
        public 	AssetModelIdentifier assetModelIdentifier;
    }
}