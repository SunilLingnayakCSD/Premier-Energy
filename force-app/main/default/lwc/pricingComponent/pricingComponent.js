import { LightningElement, wire, api, track } from 'lwc';
import getRawMaterialData from '@salesforce/apex/RawMaterialLogger.RawMaterial';
import userId from '@salesforce/user/Id';
import getUserProfileName from '@salesforce/apex/RawMaterialLogger.getUserProfileName';
import getCountryPricing from '@salesforce/apex/RawMaterialLogger.getCountryPricing';
import updateCountry from '@salesforce/apex/RawMaterialLogger.updateCountry';
import updatePricingType from '@salesforce/apex/RawMaterialLogger.updatePricingType';
import getAdminInputs from '@salesforce/apex/RawMaterialLogger.getAdminInputs';
import createVariables from '@salesforce/apex/RawMaterialLogger.createVariables';
import checkVariables from '@salesforce/apex/RawMaterialLogger.checkVariables';
import updatefinals from '@salesforce/apex/RawMaterialLogger.updateFinalWP';
import updateFinalWPbyNH from '@salesforce/apex/RawMaterialLogger.updateFinalWPbyNH';
import alreadyUpdatedByKAM from '@salesforce/apex/RawMaterialLogger.alreadyUpdatedByKAM';
import grayoutforNH from '@salesforce/apex/RawMaterialLogger.grayoutforNH';
import lockingprice from '@salesforce/apex/RawMaterialLogger.lockingprice';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
//import createAttachment from '@salesforce/apex/PricingAttachment.createAttachment';
import savePricingData from '@salesforce/apex/PricingAttachment.savePricingData';
import generatePricingAttachment from '@salesforce/apex/PricingAttachment.generatePricingAttachment';
import inboundInput from '@salesforce/apex/inputInboundApex.inboundInput';
import getFreightMetadata from '@salesforce/apex/FreightChargesController.getFreightMetadata';
import metadataUpdate from '@salesforce/apex/update_MetaData.metadataUpdate';
import getSegmentMetadata from '@salesforce/apex/AopEbitda.metadataUpdate';
import getPreEbitdaSegmentMetadata from '@salesforce/apex/segmentApexClass.metadataUpdate';
import RawMaterialsNamesQueryANdUom from '@salesforce/apex/UimakeApexClass.RawMaterialsNamesQueryANdUom';
import get20FtAnd40Ft from '@salesforce/apex/pricingconfigurationApexClass.get20FtAnd40Ft';
import { NavigationMixin } from 'lightning/navigation';

export default class RawMaterialLogger extends NavigationMixin(LightningElement) {
    @api recordId;
    currentUserId = userId;
    @track countrySource = 'China';
    @track pricingType = 'Average Price';
    @track isEditable = false;
    @track oliData = [];
    @track summaryData = [];
    @track activeIndex = 0;
    @track costDataMap = new Map();
    @track variantMap = new Map();
    @track costRows = [];
    @track rawMaterialData = [];
    @track formattedData = [];
    @track rawMaterialVariantsByOliId = {};
    @track overallTotalInrWp = 0;
    @track overallTotalCentWp = 0;
    @track storeVariableIds = [];
    @track seeFinalOnly = false;
    @track filteredData = [];
    @track allData = [];
    @track searchValue = '';
    @track seaFreightData = [];
    @track inlandTransportData = [];
    @track freight = 0;
    wiredMetadataResult;
    financialParams = {};
    wiredMetadataResultadmin;
    retryCount = 0;
    segments = [];
    segmentspre = [];
    @track allDataUomMakes = [];
    @track filteredIndiaData = [];
    @track filteredDataCMV = [];
    @track filteredDataCMVUpdate = [];
    @track filteredDataIndiapdate = [];
    @track rawdata = [];
    @track outboundlogisticattachment = [];
    @track isDisabled = false;
    @track isUpdateByNationalHead = false;
    @track isAlreadyUpdatedbyKam = false;
    @track isgrayoutforNH = false;
    @track isLockPrice = false;

    countryOptions = [
        { label: 'China', value: 'China' },
        { label: 'Malaysia', value: 'Malaysia' },
        { label: 'Vietnam', value: 'Vietnam' }
    ];

    pricingOptions = [
        { label: 'Average Price', value: 'Average Price' },
        { label: 'Low Price', value: 'Low Price' }
    ];
    @wire(inboundInput)
    wiredData(result) {
        this.wiredDataResult = result;
        if (result.data) {
            this.allData = result.data;
            this.filterData();
        } else if (result.error) {
            console.log('inbound error : ', result.error);
        }
    }
    filterData() {
        this.filteredData = this.allData.filter(item => {
            const nameMatch = item.Name?.toLowerCase().includes(this.searchValue);
            const countryMatch = this.countrySource ?
                this.hasCountryData(item, this.countrySource) :
                true;
            return nameMatch && countryMatch;
        });
    }
    hasCountryData(item, country) {
        const prefix = country === 'Vietnam' ? 'Vietnam_' : country + '_';
        return Object.keys(item).some(field =>
            field.startsWith(prefix) && item[field] != null
        );
    }
    @wire(getFreightMetadata)
    wiredFreight(result) {
        this.wiredMetadataResult = result;
        const { data, error } = result;

        if (data) {
            this.processData(data);
            this.retryCount = 0;
        } else if (error) {
            console.log('error freight : ', error);
        }
    }
    processData(data) {
        let keyCounter = 1;

        // Sea Freight
        this.seaFreightData = [
            this.createFreightRow(keyCounter++, '20 Ft', ['China', 'Vietnam', 'Malaysia']),
            this.createFreightRow(keyCounter++, '40 Ft', ['China', 'Vietnam', 'Malaysia'])
        ];

        // Inland Transport
        this.inlandTransportData = [
            this.createFreightRow(keyCounter++, '20 Ft', ['China', 'Vietnam', 'Malaysia']),
            this.createFreightRow(keyCounter++, '40 Ft', ['China', 'Vietnam', 'Malaysia'])
        ];

        // Map metadata to UI
        data.forEach(record => {
            const country = record.MasterLabel;

            // Sea Freight
            this.seaFreightData.forEach(row => {
                const field = row.containerSize === '20 Ft'
                    ? 'Sea_Frieght_USD_20Ft__c'
                    : 'Sea_Frieght_USD_40Ft__c';

                if (['China', 'Vietnam', 'Malaysia'].includes(country)) {
                    this.updateRowData(row, record, country, field);
                }
            });

            // Inland Transport
            if (['China', 'Vietnam', 'Malaysia'].includes(country)) {
                this.inlandTransportData.forEach(row => {
                    const field = row.containerSize === '20 Ft'
                        ? 'Inland_Transport_INR_20Ft__c'
                        : 'Inland_Transport_INR_40Ft__c';
                    this.updateRowData(row, record, country, field);
                });
            }
        });
    }
    createFreightRow(key, containerSize, countries) {
        const tempValues = {};
        const formattedValues = {};
        const DeveloperNames = {};
        countries.forEach(c => {
            tempValues[c] = null;
            formattedValues[c] = '';
        });

        return { key, containerSize, isEdit: false, tempValues, formattedValues, DeveloperNames };
    }

    updateRowData(row, record, country, field) {
        if (record[field] !== undefined && row.tempValues.hasOwnProperty(country)) {
            row.tempValues[country] = record[field];
            row.formattedValues[country] = this.formatNumber(record[field]);
            row.DeveloperNames[country] = record.DeveloperName;
        }
    }
    formatNumber(value) {
        return value !== null && value !== undefined ? value.toFixed(2) : '';
    }
    @wire(metadataUpdate)
    wiredMetadata(result) {
        this.wiredMetadataResultadmin = result;
        const { data, error } = result;
        if (data) {
            this.financialParams = { ...data[0] };
        } else if (error) {
            console.log('admin attachment error : ', error);
        }
    }

    @wire(getSegmentMetadata)
    wiredAOP({ data, error }) {
        if (data) {
            this.segments = data.map(record => ({
                masterLabel: record.MasterLabel,
                dcr: record.DCR__c,
                ndcr: record.NDCR__c
            }));

        } else if (error) {
            console.log('aop error : ', error);
        }
    }

    @wire(getPreEbitdaSegmentMetadata)
    wiredpreebitda({ data, error }) {
        if (data) {
            this.segmentspre = data.map(record => ({
                masterLabel: record.MasterLabel,
                dcr: record.DCR__c,
                ndcr: record.NDCR__c
            }));
        } else if (error) {
            console.log('pre ebitda error : ', error);
        }
    }
    @wire(RawMaterialsNamesQueryANdUom, { searchKey: '$searchValue' })
    wiredRawMaterialsUom(result) {
        const { data, error } = result;
        if (data) {
            this.allDataUomMakes = data;
            this.filteredIndiaData = this.allDataUomMakes.filter(
                record => record.India_Average_Price__c > 0
            );
            this.filteredDataIndiapdate = this.filteredIndiaData.map(item => ({
                "Raw Material Name": item.Name,
                "UOM": item.UOM__c,
                "India Make1": item.India_Make1__c || 0,
                "India Make2": item.India_Make2__c || 0,
                "India Make3": item.India_Make3__c || 0,
                "India Make4": item.India_Make4__c || 0,
                "India Low Price": item.India_Low_Price__c || 0,
                "India Average Price": item.India_Average_Price__c || 0
            }));

            if (this.countrySource == 'China') {
                this.filteredDataCMV = this.allDataUomMakes.filter(
                    record => record.China_Average_Price__c >= 0 ? record.India_Average_Price__c == 0 : record
                );
                this.filteredDataCMVUpdate = this.filteredDataCMV.map(item => ({
                    "Raw Material Name": item.Name,
                    "UOM": item.UOM__c,
                    "China Make1": item.China_Make1__c || 0,
                    "China Make2": item.China_Make2__c || 0,
                    "China Make3": item.China_Make3__c || 0,
                    "China Make4": item.China_Make4__c || 0,
                    "China Low Price": item.China_Low_Price__c || 0,
                    "China Average Price": item.China_Average_Price__c || 0
                }));

            } else if (this.countrySource == 'Malaysia') {
                this.filteredDataCMV = this.allDataUomMakes.filter(
                    record => record.Malaysia_Average_Price__c >= 0 ? record.India_Average_Price__c == 0 : record
                );
                this.filteredDataCMVUpdate = this.filteredDataCMV.map(item => ({
                    "Raw Material Name": item.Name,
                    "UOM": item.UOM__c,
                    "Malaysia Make1": item.Malaysia_Make1__c || 0,
                    "Malaysia Make2": item.Malaysia_Make2__c || 0,
                    "Malaysia Make3": item.Malaysia_Make3__c || 0,
                    "Malaysia Make4": item.Malaysia_Make4__c || 0,
                    "Malaysia Low Price": item.Malaysia_Low_Price__c || 0,
                    "Malaysia Average Price": item.Malaysia_Average_Price__c || 0
                }));
            } else if (this.countrySource == 'Vietnam') {
                this.filteredDataCMV = this.allDataUomMakes.filter(
                    record => record.Vietnam_Average_Price__c >= 0 ? record.India_Average_Price__c == 0 : record
                );
                this.filteredDataCMVUpdate = this.filteredDataCMV.map(item => ({
                    "Raw Material Name": item.Name,
                    "UOM": item.UOM__c,
                    "Vietnam Make1": item.Vietnam_Make1__c || 0,
                    "Vietnam Make2": item.Vietnam_Make2__c || 0,
                    "Vietnam Make3": item.Vietnam_Make3__c || 0,
                    "Vietnam Make4": item.Vietnam_Make4__c || 0,
                    "Vietnam Low Price": item.Vietnam_Low_Price__c || 0,
                    "Vietnam Average Price": item.Vietnam_Average_Price__c || 0
                }));
            } else {
                this.filteredDataCMVUpdate = [];
            }

        } else if (error) {
            console.error('Error fetching data: ', error.body.message);
        }
    }

    @wire(get20FtAnd40Ft)
    wiredMaterials2040(result) {
        if (result.data) {
            this.rawdata = result.data.map(item => ({
                "UOM": item.UOM__c,
                "Raw Material": item.Name,
                "Qty (20 Ft)": item.Qty_20_Ft__c || 0,
                "Qty (40 Ft)": item.Qty_40_Ft__c || 0
            }));
        }
    }
    handleCreateAttachment() {
        this.isDisabled = true;
        console.log('rawJson--> : ', JSON.stringify(this.oliData[this.activeIndex]));
        console.log('costRows--> : ', JSON.stringify(this.costRows));
        console.log('filtereddata inbound : ', JSON.stringify(this.filteredData));
        console.log('seaFreightData--> : ', JSON.stringify(this.seaFreightData));
        console.log('inlandTransportData--> : ', JSON.stringify(this.inlandTransportData));
        console.log('financialParams--> : ', JSON.stringify(this.financialParams));
        console.log('aop ebitda--> : ', JSON.stringify(this.segments));
        console.log('pre ebitda--> : ', JSON.stringify(this.segmentspre));
        console.log('India Uom and make--> : ', JSON.stringify(this.filteredDataIndiapdate));
        console.log('Country based Uom and make--> : ', JSON.stringify(this.filteredDataCMVUpdate));
        console.log('2040 packaging --. : ', JSON.stringify(this.rawdata));
        console.log('outbound logistic attachment --> : ', JSON.stringify(this.outboundlogisticattachment));
        /* createAttachment({ recordId: this.recordId, rawJson: JSON.stringify(this.oliData[this.activeIndex]), costRows: JSON.stringify(this.costRows), inboundlog: JSON.stringify(this.filteredData), finalPrice: this.summaryTotals.finalPrice, finalPriceinCent: this.summaryTotals.finalPriceinCent, fileName: 'PricingSummary', countrySource: this.countrySource,seaFreightData:JSON.stringify(this.seaFreightData),inlandTransportData:JSON.stringify(this.inlandTransportData) })
             .then((result) => {
                 console.log('result attachment : ', result);
             })
             .catch(error => {
                 console.log('error attachment : ', error);
             });*/
        
                generatePricingAttachment({ recordId: this.recordId, finalPrice: this.summaryTotals.finalPrice, finalPriceinCent: this.summaryTotals.finalPriceinCent, fileName: 'PricingSummary', countrySource: this.countrySource })
                    .then((result) => {
                        console.log('result attachment : ', result);
                        this.showSuccessToast('Attachment downloaded successfully!');
                        this.closeModal();
                    })
                    .catch(error => {
                        console.log('error attachment : ', error);
                        this.showErrorToast('Download Failed');
                    });
           
    }

    @wire(getCountryPricing, { oppId: '$recordId' })
    wiredPricing({ error, data }) {
        if (data) {
            console.log('data cp==> : ', data);
            this.countrySource = data.countrySource;
            this.pricingType = data.pricingType;
        } else if (error) {
            console.error(error);
        }
    }

    connectedCallback() {
        getUserProfileName({ userId: this.currentUserId })
            .then(profileName => {
                console.log('profileName : ', profileName);
                if (profileName == 'Key Accounts National Head' || profileName == 'System Administrator') {
                    this.isEditable = true;
                    this.isUpdateByNationalHead = true;
                    grayoutforNH({ oppId: this.recordId }).then(result => {
                        console.log('grayoutforNH result : ', result);
                        if (result == true) {
                            this.isgrayoutforNH = true;
                        } else {
                            this.isgrayoutforNH = false;
                        }

                    }).catch(error => {
                        console.log('grayoutforNH err : ', error);
                    })
                    lockingprice({ oppId: this.recordId }).then(result => {
                        console.log('lockingprice result : ', result);
                        if (result == true) {
                            this.isLockPrice = true;
                        } else {
                            this.isLockPrice = false;
                        }
                    }).catch(error => {
                        console.log('lockingprice err : ', error);
                    })
                }
                if (profileName == 'Key Accounts Region Head') {
                    this.seeFinalOnly = true;
                    console.log('seeFinalOnly : ', this.seeFinalOnly);
                    console.log('al recordID--> : ', this.recordId);
                    alreadyUpdatedByKAM({ oppId: this.recordId }).then(result => {
                        console.log('alreadyUpdatedByKAM result : ', result);
                        if (result == true) {
                            this.isAlreadyUpdatedbyKam = true;
                        } else {
                            this.isAlreadyUpdatedbyKam = false;
                        }
                    }).catch(error => {
                        console.log('alreadyUpdatedByKAM error  : ', error);
                    })
                    lockingprice({ oppId: this.recordId }).then(result => {
                        console.log('lockingprice result : ', result);
                        if (result == true) {
                            this.isLockPrice = true;
                        } else {
                            this.isLockPrice = false;
                        }
                    }).catch(error => {
                        console.log('lockingprice err : ', error);
                    })
                }
            })
            .catch(error => {
                console.error('Error fetching profile:', error);
            });
    }
    get isDisabled() {
        return !this.isEditable;
    }

    get isgrayoutforNHfun() {
        return !this.isgrayoutforNH;
    }

    get isAlreadyUpdatedbyKam() {
        return this.isAlreadyUpdatedbyKam;
    }

    get currentProduct() {
        console.log('currentProduct oli data --> : ',JSON.stringify(this.oliData));
        console.log('currentProduct---> : ', this.oliData[this.activeIndex]);
        return this.oliData[this.activeIndex] || {};
    }

    get currentProductName() {
        return this.currentProduct.productName || 'Product';
    }

    get totalProducts() {
        return this.oliData.length;
    }

    get currentPosition() {
        return this.activeIndex + 1;
    }

    get prevDisabled() {
        return this.activeIndex === 0;
    }

    get nextDisabled() {
        return this.activeIndex >= this.oliData.length - 1;
    }

    @wire(getRawMaterialData, {
        opportunityId: '$recordId',
        pricingType: '$pricingType',
        countrySource: '$countrySource'
    })
    wiredRawMaterials({ data, error }) {
        if (data) {
            console.log('data raw--> : ', JSON.stringify(data));
            this.handleRawMaterialsAsync(data);
        } else {
            console.error('Wire error:', error);
        }
    }
    async handleRawMaterialsAsync(data) {
        try {
            const key = Object.keys(data)[0]; 

            const recordsArray = data[key];

            const record = recordsArray && recordsArray.length > 0 ? recordsArray[0] : null;

            if (!record) {
                console.error('No records found inside data[' + key + ']');
                return;
            }

            console.log('record.isFromNH : ', record.isFromNH);
            console.log('record.jsonRows : ', record.jsonRows);

            if (record.isFromNH && record.jsonRows) {
                this.oliData = Array.isArray(record.jsonRows) ? record.jsonRows : [record.jsonRows];
            } else {
                const cleanData = JSON.parse(JSON.stringify(data)); // Breaks Proxy
                console.log('cleanData--> : ', cleanData);

                const processedOlis = await Promise.all(
                    Object.entries(cleanData).map(async ([oliId, materials], index) => {
                        const processed = await this.processMaterials(materials, index, oliId);
                        const totals = this.calculateTotals(processed);

                        return {
                            oliId,
                            productName: materials[0]?.productName || 'Product',
                            materials: processed,
                            ...totals
                        };
                    })
                );

                this.oliData = processedOlis;           
            this.activeIndex = 0;
            }
            this.loadCostData();
        } catch (error) {
            console.error('Async processing failed-->:', error);
            if (error.body && error.body.message) {
                console.error('Error message:', error.body.message);
            } else {
                console.error('Error:', error.message);
            }
        }
    }


    async processMaterials(materials, oliIndex, oliId) {
        // Save variants per oliId for quick access during variant change
        this.rawMaterialVariantsByOliId[oliId] = materials;


        console.log('materials--from above method--> : ', materials);
        let allRawMaterialVariants = materials;
        console.log('allRawMaterialVariants--> : ', JSON.stringify(allRawMaterialVariants));
        const variableMaterialsforapex = materials;

        // Step 1: Filter and map base raw material data
        let rawMaterialData = materials
            .filter(item => item.netBoQData !== 0 && item.netBoQData !== null && item.netBoQData !== undefined && item.isDefaultSkip == false)
            .map((material, mIndex) => ({
                ...material,
                dataId: `${oliIndex}-${mIndex}`,

                // Original formatting
                formattedRawCostUSD: this.formatCurrency(material.rawCostUSD, 'USD'),
                formattedRawCostINR: this.formatDecimal(material.rawCostINR),
                formattedLogistics: this.formatDecimal(material.logisticsCalculation),
                formattedInsurance: this.formatDecimal(material.insurancePercentage),
                formattedDuty: this.formatDecimal(material.totalCostWithMargin),
                formattedDdp: this.formatDecimal(material.totalCostWithMarginAdded),
                formattedInrWp: this.formatDecimal(material.rawCostINRPerWattage),
                formattedCentsDp: this.formatDecimal(material.rawCostUSDPerWattage),

                // Required structure
                id: `row-${mIndex}`,
                rawMaterialName: material.rawMaterialName || '',
                uom: material.uom || '',
                requiredQuantityPerUnit: material.netBoQData || 0,
                actualPriceUsed: material.actualPriceUsed || 0,
                rawCostUSD: material.rawCostUSD || 0,
                rawCostINR: material.rawCostINR || 0,
                logisticsCalculation: material.logisticsCalculation || 0,
                insurancePercentage: material.insurancePercentage || 0,
                DutyModule: material.totalCostWithMargin || 0,
                Ddp: material.totalCostWithMarginAdded || 0,
                InrWp: material.rawCostINRPerWattage || 0,
                centsDp: material.rawCostUSDPerWattage || 0,
                isVariable: material.isVariable || false,
                isDefaultSkip: material.isDefaultSkip || false,
                defaultVariantGroupId: material.defaultVariantGroupId || '',
                variantOptions: [],
                rawMaterialId: material.rawMaterialId || ''
            }));

        const variableMaterials = variableMaterialsforapex.filter(variant => variant.isVariable == true && variant.isDefaultSkip == false).map(variant => variant.rawMaterialId);
        console.log('variableMaterials--> : ', JSON.stringify(variableMaterials));

        await checkVariables({ oppId: this.recordId, rawMaterialIds: variableMaterials, oliId: oliId }).then(result => {
            console.log('fetch changed variables result--> : ', JSON.stringify(result));
            const variablesfromapex = result;
            this.storeVariableIds = result;
            console.log('storeVariableIds--> : ', JSON.stringify(this.storeVariableIds));
            console.log('variablesfromapex--> : ', variablesfromapex);
            this.storeVariableIds.forEach(material => {
                console.log('changed material ids --> : ', material);
            });


            //console.log('storedVariantId local--> : ', storedVariantId);
            console.log('storeVariableIds for loop--> : ', this.storeVariableIds);
            console.log('storeVariableIds for loop stringify--> : ', JSON.stringify(this.storeVariableIds));
            this.storeVariableIds.forEach(storedVariantId => {
                console.log('storedVariantId material ids --> : ', storedVariantId);

                if (storedVariantId != null) {
                    const selectedVariant = allRawMaterialVariants.find(variant => variant.rawMaterialId == storedVariantId);
                    console.log('selectedVariant--> : ', JSON.stringify(selectedVariant));
                    console.log('rawMaterialData--> : ', JSON.stringify(rawMaterialData));
                    if (selectedVariant) {
                        const materialCheck = rawMaterialData.find(m => m.rawMaterialId == selectedVariant.rawMaterialId);
                        console.log('materialCheck--> : ', JSON.stringify(materialCheck));
                        if (!materialCheck) {
                            console.log('OUInside materialCheck : ',);
                            rawMaterialData = rawMaterialData.map(material => {
                                if (material.rawMaterialId === selectedVariant.defaultVariantGroupId) {
                                    return Object.assign({}, material, {
                                        rawMaterialName: selectedVariant.rawMaterialName || '',
                                        uom: selectedVariant.uom || '',
                                        requiredQuantityPerUnit: selectedVariant.netBoQData || 0,
                                        actualPriceUsed: selectedVariant.actualPriceUsed || 0,
                                        rawCostUSD: selectedVariant.rawCostUSD || 0,
                                        rawCostINR: selectedVariant.rawCostINR || 0,
                                        logisticsCalculation: selectedVariant.logisticsCalculation || 0,
                                        insurancePercentage: selectedVariant.insurancePercentage || 0,
                                        DutyModule: selectedVariant.totalCostWithMargin || 0,
                                        Ddp: selectedVariant.totalCostWithMarginAdded || 0,
                                        InrWp: selectedVariant.rawCostINRPerWattage || 0,
                                        centsDp: selectedVariant.rawCostUSDPerWattage || 0,
                                        isVariable: selectedVariant.isVariable || false,
                                        isDefaultSkip: selectedVariant.isDefaultSkip || false,
                                        defaultVariantGroupId: selectedVariant.defaultVariantGroupId || '',
                                        selectedVariantId: storedVariantId,

                                        formattedRawCostUSD: this.formatCurrency(selectedVariant.rawCostUSD, 'USD'),
                                        formattedRawCostINR: this.formatDecimal(selectedVariant.rawCostINR),
                                        formattedLogistics: this.formatDecimal(selectedVariant.logisticsCalculation),
                                        formattedInsurance: this.formatDecimal(selectedVariant.insurancePercentage),
                                        formattedDuty: this.formatDecimal(selectedVariant.totalCostWithMargin),
                                        formattedDdp: this.formatDecimal(selectedVariant.totalCostWithMarginAdded),
                                        formattedInrWp: this.formatDecimal(selectedVariant.rawCostINRPerWattage),
                                        formattedCentsDp: this.formatDecimal(selectedVariant.rawCostUSDPerWattage)
                                    });
                                }
                                return material;
                            });

                            // this.formatData();
                            console.log('Updated rawMaterialData after applying selectedVariant:', JSON.stringify(rawMaterialData));
                        }
                    }
                }
            });



            rawMaterialData.forEach(material => {
                if (material.isVariable) {
                    console.log('Variable material name--> : ', material.rawMaterialName);
                    console.log('Variable material id--> : ', material.rawMaterialId);
                    console.log('--- All Raw Material Variants ---');
                    allRawMaterialVariants.forEach(variant => {
                        console.log(
                            `Name: ${variant.rawMaterialName}, ` +
                            `isVariable: ${variant.isVariable}, ` +
                            `defaultVariantGroupId: ${variant.defaultVariantGroupId}`
                        );
                    });
                    rawMaterialData.forEach(variant => {
                        console.log(
                            `Name: ${variant.rawMaterialName}, ` +
                            `isVariable: ${variant.isVariable}, ` +
                            `defaultVariantGroupId: ${variant.defaultVariantGroupId}`
                        );
                    });
                    console.log('---------------------------------');
                    const matchingVariants = allRawMaterialVariants
                        .filter(variant =>
                            variant.isVariable == true &&
                            (variant.defaultVariantGroupId == material.rawMaterialId ||
                                variant.rawMaterialId == material.defaultVariantGroupId)
                        )
                        .map(variant => ({
                            label: variant.rawMaterialName,
                            value: variant.rawMaterialId
                        }));
                    console.log('matchingVariants--> : ', JSON.stringify(matchingVariants));

                    const selfOption = {
                        label: material.rawMaterialName,
                        value: material.rawMaterialId
                    };
                    console.log('material.variantOptions--> : ', JSON.stringify(material.variantOptions));
                    const isSelfIncluded = matchingVariants.some(opt => opt.value === selfOption.value);

                    material.variantOptions = isSelfIncluded
                        ? matchingVariants
                        : [selfOption, ...matchingVariants];
                    material.selectedVariantId ??= material.rawMaterialId;
                    console.log(`Variants for ${material.rawMaterialName}: `, JSON.stringify(material.variantOptions));
                }
            });

            console.log('rawMaterials-->', JSON.stringify(rawMaterialData));

        })
            .catch(error => {
                console.error('Error fetching variable materials:', error);
            });

        return rawMaterialData; // initial return, full processing continues asynchronously
    }


    calculateTotals(materials) {
        const totals = materials.reduce((acc, material) => {
            acc.totalInrWp += parseFloat(material.InrWp) || 0;
            acc.totalCentWp += parseFloat(material.centsDp) || 0;
            return acc;
        }, { totalInrWp: 0, totalCentWp: 0 });

        totals.totalInrWp = parseFloat(totals.totalInrWp.toFixed(2));
        totals.totalCentWp = parseFloat(totals.totalCentWp.toFixed(2));

        return totals;
    }

    async loadCostData() {
        try {
            const result = await getAdminInputs({ oppId: this.recordId });
            this.costDataMap = new Map(Object.entries(result));
            this.processCostRows();

            this.updateSummary();
        } catch (error) {
            console.error('Error loading cost data:', JSON.stringify(error));
            if (error.body?.message) {
                console.error('Error message:', error.body.message);
            } else {
                console.error('Error:', error.message);
            }
        }
    }


    processCostRows() {
        const data = this.costDataMap.get(this.currentProduct.oliId) || {};
        if (data.isFromNH && data.jsonRows) {
            console.log('data.isFromNH : ', data.isFromNH);
            console.log('data.jsonRows : ', data.jsonRows);
            this.costRows = data.jsonRows;
            const finalPriceRow = data.jsonRows.find(row => row.label === 'FINAL Wp PRICE');
            const pbtRow = data.jsonRows.find(row => row.label === 'PBT Margin');
            const moduleFinanceRow = data.jsonRows.find(row => row.label === 'Module Finance Cost(Cents/Wp)');

            const finalpriceINR = parseFloat(finalPriceRow?.col2 || 0);
            const finalpriceCent = parseFloat(finalPriceRow?.col3 || 0);
            const pbtINR = parseFloat(pbtRow?.col2 || 0);
            const totalforebitda = finalpriceINR - pbtINR;
            const moduleFinanceINR = parseFloat(moduleFinanceRow?.col2 || 0);

            const currentOliId = this.currentProduct.oliId;
            const existingCostData = this.costDataMap.get(currentOliId) || {};
            const clonedCostData = { ...existingCostData, finalpriceINR: parseFloat(finalpriceINR), finalpriceCent: parseFloat(finalpriceCent), totalforebitda: parseFloat(totalforebitda), moduleFinanceINR: parseFloat(moduleFinanceINR) };
            this.costDataMap.set(currentOliId, clonedCostData);
            console.log('costDataMap---> : ', JSON.stringify(Array.from(this.costDataMap.entries())));

            this.updateSummary();
        } else {
            console.log('this.currentProduct.oliId -->: ', this.currentProduct.oliId);
            console.log('this.currentProduct.totalInrWp -->: ', this.currentProduct.totalInrWp);
            const totalvalue = parseFloat(this.currentProduct.totalInrWp) || 0;
            console.log('Admin data--> : ', data);
            console.log('outbound logistic for attachment--> : ', data.outboundLogforattachment);
            this.outboundlogisticattachment = data.outboundLogforattachment;
            console.log('cbitc--> : ', data.cbitc);
            console.log('noTrucksReq--> : ', data.noTrucksReq);
            console.log('totalInrWp--> : ', totalvalue);
            console.log('data.warrantyInsurance--> : ', data.warrantyInsurance);
            console.log('data.rfidCostINR--> : ', data.rfidCostINR);
            console.log('data.moduleOverheadINR--> : ', data.moduleOverheadINR);
            console.log('addvalues--> : ', parseFloat(totalvalue + data.rfidCostINR + data.moduleOverheadINR));
            console.log('freight : ', data.freight);
            this.freight = data.freight;
            let moduleWarrantyInsuranceCostINR = 0.00;
            let moduleWarrantyInsuranceCostCent = 0.00;
            if (data.thirdpartywarranty == 'Applicable') {
                moduleWarrantyInsuranceCostINR = (totalvalue + data.rfidCostINR + data.moduleOverheadINR) * (data.warrantyInsurance / 100);
                console.log('moduleWarrantyInsuranceCostINR--> : ', moduleWarrantyInsuranceCostINR);
                moduleWarrantyInsuranceCostCent = ((moduleWarrantyInsuranceCostINR * 100) / data.rbi);
                moduleWarrantyInsuranceCostINR = Number(moduleWarrantyInsuranceCostINR.toFixed(2));
                moduleWarrantyInsuranceCostCent = moduleWarrantyInsuranceCostCent.toFixed(2);
            } else {
                moduleWarrantyInsuranceCostINR = 0.00;
                moduleWarrantyInsuranceCostCent = 0.00;
            }
            var bGradeModuleLossINR = ((totalvalue + data.rfidCostINR + data.moduleOverheadINR + data.moduleFinanceINR + data.cellBOMINR + data.cellOverheadINR + data.cellFinanceINR + moduleWarrantyInsuranceCostINR) * (data.bgrademodulediscount / 100) * (data.bgrademoduleyield / 100));
            console.log('total for bgrade : ', (totalvalue + data.rfidCostINR + data.moduleOverheadINR + data.moduleFinanceINR + data.cellBOMINR + data.cellOverheadINR + data.cellFinanceINR + moduleWarrantyInsuranceCostINR));
            console.log('bGradeModuleLossINR cal--> : ', bGradeModuleLossINR);
            var bGradeModuleLossCent = ((bGradeModuleLossINR * 100) / data.rbi);
            bGradeModuleLossINR = Number(bGradeModuleLossINR);
            // bGradeModuleLossINR = Number(this.formatDecimal(bGradeModuleLossINR));
            console.log('bGradeModuleLossINR format--> : ', bGradeModuleLossINR);
            bGradeModuleLossCent = Number(bGradeModuleLossCent);
            const abgCostINR = Number((
                (parseFloat(data.abgvalue) || 0) *
                (parseFloat(data.abgpbgcost / 100) || 0) /
                365 *
                (parseFloat(data.abgvalidity) || 0) /
                (parseFloat(data.projectcapacity) || 1) /
                1000000
            ).toFixed(2));
            console.log('abgCostINR--> : ', abgCostINR);
            const abgCostCent = this.formatDecimal((abgCostINR * 100) / data.rbi);
            console.log('abgCostCent--> : ', (abgCostINR * 100) / data.rbi);
            console.log('data.pbgvalue--> : ', data.pbgvalue);
            console.log('data.abgpbgcost--> : ', data.abgpbgcost);
            console.log('data.pbgvalidity--> : ', data.pbgvalidity);
            console.log('data.projectcapacity--> : ', data.projectcapacity);
            const pbgCostINR = Number((
                (parseFloat(data.pbgvalue) || 0) *
                (parseFloat(data.abgpbgcost / 100) || 0) /
                365 *
                (parseFloat(data.pbgvalidity) || 0) /
                (parseFloat(data.projectcapacity) || 1) /
                1000000
            ).toFixed(2));
            console.log('pbgCostINR--> : ', pbgCostINR);
            const pbgCostCent = ((pbgCostINR * 100) / data.rbi).toFixed(2);
            console.log('data.insurancepremiumcost--> : ', data.insurancepremiumcost);
            var transitinsurancecostINR = parseFloat(totalvalue + data.rfidCostINR + data.moduleOverheadINR + data.moduleFinanceINR + data.cellBOMINR + data.cellOverheadINR + data.cellFinanceINR + moduleWarrantyInsuranceCostINR + bGradeModuleLossINR + abgCostINR + pbgCostINR + data.outboundlogisticsINR + data.exportfreightchargesINR) * (data.insurancepremiumcost / 100);
            var transitinsurancecostCent = (transitinsurancecostINR * 100 / data.rbi);
            transitinsurancecostINR = Number(transitinsurancecostINR);
            console.log('transitinsurancecostINR--> : ', transitinsurancecostINR);
            transitinsurancecostCent = transitinsurancecostCent;
            console.log('data.paymentterm--> : ', data.paymentterm);
            console.log('data.lcinterestcost--> : ', data.lcinterestcost);
            console.log('data.lcusanceperiod--> : ', data.lcusanceperiod);
            const sumforlcinterest = parseFloat(totalvalue + data.rfidCostINR + data.moduleOverheadINR + data.moduleFinanceINR + data.cellBOMINR + data.cellOverheadINR + data.cellFinanceINR + moduleWarrantyInsuranceCostINR + bGradeModuleLossINR + abgCostINR + pbgCostINR + data.outboundlogisticsINR + data.exportfreightchargesINR);
            console.log('sumforlcinterest--> : ', sumforlcinterest);
            let lcinterestcostINR = 0.00;
            let lcinterestcostCent = 0.00;
            console.log('data.paymenttrembalance--> : ', data.paymenttrembalance);
            if (data.paymenttrembalance == 'LC') {
                lcinterestcostINR = (
                    (parseFloat(sumforlcinterest)) *
                    (parseFloat(1 - (data.paymentterm / 100))) *
                    parseFloat(data.lcinterestcost / 100) / 365 *
                    parseFloat(data.lcusanceperiod)
                );
                lcinterestcostINR = Number(lcinterestcostINR);
                lcinterestcostCent = (lcinterestcostINR * 100 / data.rbi);
            } else if (data.paymenttrembalance == 'RTGS') {
                lcinterestcostINR = 0.00;
                lcinterestcostCent = 0.00;
            }
            console.log('totalvalue:', totalvalue);
            console.log('rfidCostINR:', data.rfidCostINR);
            console.log('moduleOverheadINR:', data.moduleOverheadINR);
            console.log('moduleFinanceINR:', data.moduleFinanceINR);
            console.log('cellBOMINR:', data.cellBOMINR);
            console.log('cellOverheadINR:', data.cellOverheadINR);
            console.log('cellFinanceINR:', data.cellFinanceINR);
            console.log('moduleWarrantyInsuranceCostINR:', moduleWarrantyInsuranceCostINR);
            console.log('bGradeModuleLossINR:', bGradeModuleLossINR);
            console.log('abgCostINR:', abgCostINR);
            console.log('pbgCostINR:', pbgCostINR);
            console.log('outboundlogistics:', data.outboundlogisticsINR);
            console.log('exportfreightchargesINR:', data.exportfreightchargesINR);
            console.log('transitinsurancecostINR:', transitinsurancecostINR);
            console.log('lcinterestcostINR:', lcinterestcostINR);


            //const totalforebitda = (parseFloat(totalvalue) + parseFloat(data.rfidCostINR) + parseFloat(data.moduleOverheadINR) + parseFloat(data.moduleFinanceINR) + parseFloat(data.cellBOMINR) + parseFloat(data.cellOverheadINR) + parseFloat(data.cellFinanceINR) + parseFloat(moduleWarrantyInsuranceCostINR) + parseFloat(bGradeModuleLossINR) + parseFloat(abgCostINR) + parseFloat(pbgCostINR) + parseFloat(data.outboundlogistics) + parseFloat(data.exportfreightchargesINR) + parseFloat(transitinsurancecostINR) + parseFloat(lcinterestcostINR));
            // totalforebitda = totalforebitda.toFixed(2);
            const totalforebitda =
                totalvalue +
                data.rfidCostINR +
                data.moduleOverheadINR +
                data.moduleFinanceINR +
                data.cellBOMINR +
                data.cellOverheadINR +
                data.cellFinanceINR +
                moduleWarrantyInsuranceCostINR +
                bGradeModuleLossINR +
                abgCostINR +
                pbgCostINR +
                data.outboundlogisticsINR +
                data.exportfreightchargesINR +
                transitinsurancecostINR +
                lcinterestcostINR;


            console.log('totalforebitda--> : ', totalforebitda);
            console.log('data.ebitda--> : ', data.ebitda);
            const ebitdaINR = Number(((data.ebitda / 100) * (totalforebitda - data.moduleFinanceINR)).toFixed(2));
            const ebitdaCent = (ebitdaINR * 100 / data.rbi).toFixed(2);
            const pbtINR = Number((ebitdaINR - data.moduleFinanceINR).toFixed(2));
            const pbtCent = (pbtINR * 100 / data.rbi).toFixed(2);
            console.log('pbtINR--> : ', pbtINR);

            const finalpriceINR = (totalforebitda + parseFloat(pbtINR)).toFixed(2);
            const finalpriceCent = (finalpriceINR * 100 / data.rbi).toFixed(2);
            console.log('data.rfidCostINR : ', data.rfidCostINR);
            console.log('data.moduleOverheadINR : ', data.moduleOverheadINR);
            console.log('outboundlogisticsINR--> : ', data.outboundlogisticsINR);
            let formatrfidCostINR = this.formatDecimal(data.rfidCostINR);

            this.costRows = [
                { label: 'RFID reader cost', col2: formatrfidCostINR, col3: this.formatDecimal(data.rfidCostCents) },
                { label: 'Module Overhead cost (cents/Wp)', col2: this.formatDecimal(data.moduleOverheadINR), col3: this.formatDecimal(data.moduleOverheadCents) },
                { label: 'Module Finance Cost(Cents/Wp)', col2: this.formatDecimal(data.moduleFinanceINR), col3: this.formatDecimal(data.moduleFinanceCents) },
                { label: 'Cell BOM Cost (Cents/Wp)', col2: this.formatDecimal(data.cellBOMINR), col3: this.formatDecimal(data.cellBOMCents) },
                { label: 'Cell - Overhead Cost (Cents/Wp)', col2: this.formatDecimal(data.cellOverheadINR), col3: this.formatDecimal(data.cellOverheadCents) },
                { label: 'Cell- Finance Cost(Cents/Wp)', col2: this.formatDecimal(data.cellFinanceINR), col3: this.formatDecimal(data.cellFinanceCents) },
                { label: 'Module Warranty insurance Cost', col2: moduleWarrantyInsuranceCostINR, col3: moduleWarrantyInsuranceCostCent },
                { label: 'B-Grade Module Loss', col2: this.formatDecimal(bGradeModuleLossINR), col3: this.formatDecimal(bGradeModuleLossCent) },
                { label: 'ABG Cost', col2: abgCostINR, col3: abgCostCent },
                { label: 'PBG Cost', col2: pbgCostINR, col3: pbgCostCent },
                { label: 'outbound logistics', col2: this.formatDecimal(data.outboundlogisticsINR), col3: this.formatDecimal(data.outboundlogisticsCent) },
                { label: 'Export Freight Charges', col2: this.formatDecimal(data.exportfreightchargesINR), col3: this.formatDecimal(data.exportfreightchargesCent) },
                { label: 'Transit Insurance Cost', col2: this.formatDecimal(transitinsurancecostINR), col3: this.formatDecimal(transitinsurancecostCent) },
                { label: 'LC Interest Cost', col2: this.formatDecimal(lcinterestcostINR), col3: this.formatDecimal(lcinterestcostCent) },
                { label: 'EBITDA Margin', col2: ebitdaINR, col3: ebitdaCent },
                { label: 'PBT Margin', col2: pbtINR, col3: pbtCent },
                { label: 'FINAL Wp PRICE', col2: finalpriceINR, col3: finalpriceCent }
            ];

            // Save finalpriceINR in costDataMap so it can be accessed in updateSummary
            const currentOliId = this.currentProduct.oliId;
            const existingCostData = this.costDataMap.get(currentOliId) || {};
            const clonedCostData = { ...existingCostData, finalpriceINR: parseFloat(finalpriceINR), finalpriceCent: parseFloat(finalpriceCent), totalforebitda: parseFloat(totalforebitda), moduleFinanceINR: parseFloat(data.moduleFinanceINR) };
            this.costDataMap.set(currentOliId, clonedCostData);
            console.log('costDataMap---> : ', JSON.stringify(Array.from(this.costDataMap.entries())));

            this.updateSummary();
        }


    }

    // updateSummary() {
    //     this.summaryData = this.oliData.map(oli => ({
    //         productName: oli.productName,
    //         totalInrWp: oli.totalInrWp.toFixed(2),
    //         totalCentWp: oli.totalCentWp.toFixed(2),
    //         finalPrice: this.costDataMap.get(oli.oliId)?.finalpriceINR?.toFixed(2) || '0.00'
    //     }));
    // }
    @track summaryTotals = {
        totalInrWp: '0.00',
        totalCentWp: '0.00',
        finalPrice: '0.00',
        finalPriceinCent: '0.00',
        totalforebitda: '0.00',
        moduleFinanceINR: '0.00'
    };
    updateSummary() {
        // Calculate totals for each OLI and store in summaryData
        this.summaryData = this.oliData.map(oli => {
            const costData = this.costDataMap.get(oli.oliId) || {};
            return {
                productName: oli.productName,
                totalInrWp: oli.totalInrWp,
                totalCentWp: oli.totalCentWp,
                finalPrice: costData.finalpriceINR || 0,
                finalPriceinCent: costData.finalpriceCent || 0,
                totalforebitda: costData.totalforebitda || 0,
                moduleFinanceINR: costData.moduleFinanceINR || 0
            };
        });

        // Force a refresh of the summary totals
        this.summaryTotals = this.calculateSummaryTotals();
    }

    calculateSummaryTotals() {
        if (!this.summaryData || this.summaryData.length === 0) {
            return {
                totalInrWp: '0.00',
                totalCentWp: '0.00',
                finalPrice: '0.00',
                finalPriceinCent: '0.00',
                totalforebitda: '0.00',
                moduleFinanceINR: '0.00'
            };
        }

        const totals = this.summaryData.reduce((acc, item) => {
            acc.totalInrWp += parseFloat(item.totalInrWp) || 0;
            acc.totalCentWp += parseFloat(item.totalCentWp) || 0;
            acc.finalPrice += parseFloat(item.finalPrice) || 0;
            acc.finalPriceinCent += parseFloat(item.finalPriceinCent) || 0;
            acc.totalforebitda += parseFloat(item.totalforebitda) || 0;
            acc.moduleFinanceINR += parseFloat(item.moduleFinanceINR) || 0;
            return acc;
        }, { totalInrWp: 0, totalCentWp: 0, finalPrice: 0, finalPriceinCent: 0, totalforebitda: 0, moduleFinanceINR: 0 });

        return {
            totalInrWp: totals.totalInrWp.toFixed(2),
            totalCentWp: totals.totalCentWp.toFixed(2),
            finalPrice: totals.finalPrice.toFixed(2),
            finalPriceinCent: totals.finalPriceinCent.toFixed(2),
            totalforebitda: totals.totalforebitda.toFixed(2),
            moduleFinanceINR: totals.moduleFinanceINR.toFixed(2)
        };
    }

    get summaryTotals() {
        return this.calculateSummaryTotals();
    }





    handleCountryChange(event) {
        this.countrySource = event.detail.value;
        updateCountry({ country: this.countrySource, oppId: this.recordId }).
            then(result => {
                console.log('result country : ', result);
            }).catch(error => {
                console.log('error country : ', error);
            });
    }

    handlePricingChange(event) {
        this.pricingType = event.detail.value;
        updatePricingType({ type: this.pricingType, oppId: this.recordId }).
            then(result => {
                console.log('result type : ', result);
            }).catch(error => {
                console.log('error type : ', error);
            });
    }

    handleNext() {
        if (this.activeIndex < this.oliData.length - 1) {
            this.activeIndex++;
            console.log('handleNext--> : ',);
            //this.processMaterials();
            this.processCostRows();
        }
    }

    handlePrev() {
        if (this.activeIndex > 0) {
            this.activeIndex--;
            //this.processMaterials();
            this.processCostRows();
        }
    }
    get isLastPage() {
        return this.activeIndex === this.oliData.length - 1;
    }


    async handleVariantChange(event) {
        try {
            const [oliIndex, materialIndex] = event.target.dataset.id.split('-');
            const selectedId = event.detail.value;

            const currentOli = this.oliData[oliIndex];
            console.log('currentOli.oliId--> : ', currentOli.oliId);
            const materialToUpdate = currentOli.materials[materialIndex];

            if (!materialToUpdate) {
                console.warn('Material to update not found.');
                return;
            }

            const oldRM = materialToUpdate.rawMaterialId;
            console.log('oldRM : ', oldRM);
            const allVariants = this.rawMaterialVariantsByOliId?.[currentOli.oliId] || [];

            const selectedVariant = allVariants.find(v => v.rawMaterialId === selectedId);
            console.log('selectedVariant--> : ', JSON.stringify(selectedVariant));

            if (!selectedVariant) {
                console.warn('Selected variant not found in variants list.');
                return;
            }

            // Apex call to update variant relationship
            await createVariables({
                oppId: this.recordId,
                oldRM,
                newRM: selectedId,
                oliId: currentOli.oliId
            });

            // Create a new updated material (replace instead of mutate)
            const updatedMaterial = {
                ...materialToUpdate,
                rawMaterialId: selectedId,
                rawMaterialName: selectedVariant.rawMaterialName || '',
                uom: selectedVariant.uom || '',
                requiredQuantityPerUnit: selectedVariant.netBoQData || 0,
                actualPriceUsed: selectedVariant.actualPriceUsed || 0,
                rawCostUSD: selectedVariant.rawCostUSD || 0,
                rawCostINR: selectedVariant.rawCostINR || 0,
                logisticsCalculation: selectedVariant.logisticsCalculation || 0,
                insurancePercentage: selectedVariant.insurancePercentage || 0,
                DutyModule: selectedVariant.totalCostWithMargin || 0,
                Ddp: selectedVariant.totalCostWithMarginAdded || 0,
                InrWp: selectedVariant.rawCostINRPerWattage || 0,
                centsDp: selectedVariant.rawCostUSDPerWattage || 0,
                selectedVariantId: selectedId,

                // Update formatted fields
                formattedRawCostUSD: this.formatCurrency(selectedVariant.rawCostUSD, 'USD'),
                formattedRawCostINR: this.formatDecimal(selectedVariant.rawCostINR),
                formattedLogistics: this.formatDecimal(selectedVariant.logisticsCalculation),
                formattedInsurance: this.formatDecimal(selectedVariant.insurancePercentage),
                formattedDuty: this.formatDecimal(selectedVariant.totalCostWithMargin),
                formattedDdp: this.formatDecimal(selectedVariant.totalCostWithMarginAdded),
                formattedInrWp: this.formatDecimal(selectedVariant.rawCostINRPerWattage),
                formattedCentsDp: this.formatDecimal(selectedVariant.rawCostUSDPerWattage)
            };

            // Replace the material in the array
            currentOli.materials.splice(materialIndex, 1, updatedMaterial);

            // Recalculate totals and update oli
            const updatedTotals = this.calculateTotals(currentOli.materials);
            console.log('updatedTotals--> : ', JSON.stringify(updatedTotals));
            Object.assign(this.oliData[oliIndex], updatedTotals);

            console.log(`Material updated successfully for OLI ${oliIndex}, material ${materialIndex}`);
            console.log('Material updated--> : ', JSON.stringify(this.oliData[oliIndex]));
            this.processCostRows();
            this.updateSummary();
        } catch (error) {
            console.error('Error updating variant:', error);
            if (error.body?.message) {
                console.error('Error message:', error.body.message);
            } else {
                console.error('Error:', error.message);
            }
        }
    }




    formatDecimal(value) {
        // return value?.toFixed(2) || '0.00';
        if (typeof value !== 'number') return '0.00';

        const scaled = value * 1000;
        const thirdDigit = Math.floor(scaled) % 10;
        const base = Math.floor(value * 100);

        let result;
        if (thirdDigit > 5) {
            result = (base + 1) / 100; // round up
        } else {
            result = base / 100;
        }

        return result.toFixed(2) || 0.00;
    }

    formatCurrency(value, currency) {
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: currency,
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        }).format(value || 0);
    }

    handleupdate() {
        console.log('recordId--> : ', this.recordId);
        console.log('finalprice--> : ', this.summaryTotals.finalPrice);
        console.log('finalPriceinCent--> : ', this.summaryTotals.finalPriceinCent);
        console.log('ebita--> : ', this.summaryTotals.totalforebitda);
        console.log('moduleFinanceINR--> : ', this.summaryTotals.moduleFinanceINR);
        console.log('OUTPUT : ',);
        if (this.isUpdateByNationalHead == false) {
            updatefinals({ recordId: this.recordId, finalprice: this.summaryTotals.finalPrice, finalpricecent: this.summaryTotals.finalPriceinCent, pbtvalue: this.summaryTotals.totalforebitda, moduleFinanceINR: this.summaryTotals.moduleFinanceINR, freight: this.freight }).then(result => {
                console.log('result updatefinals: ', result);
                savePricingData({ recordId: this.recordId, rawJson: JSON.stringify(this.oliData[this.activeIndex]), costRows: JSON.stringify(this.costRows), inboundlog: JSON.stringify(this.filteredData), seaFreightData: JSON.stringify(this.seaFreightData), inlandTransportData: JSON.stringify(this.inlandTransportData), financialParams: JSON.stringify(this.financialParams), aopEbitda: JSON.stringify(this.segments), preEbitda: JSON.stringify(this.segmentspre), indiaPro: JSON.stringify(this.filteredDataIndiapdate), cmvPro: JSON.stringify(this.filteredDataCMVUpdate), package2040: JSON.stringify(this.rawdata), outboundlog: JSON.stringify(this.outboundlogisticattachment) })
                    .then((result) => {
                        console.log('Save pricing data by Kam: ', result);
                    })
                    .catch(error => {
                        console.log('error saving by kam: ', error);
                    });
                this.showSuccessToast('Updated successfully!');
                this.closeModal();

            }).catch(error => {
                console.log('error updatefinals: ', error);
                this.showErrorToast('Updation Failed');
            })
        }

        if (this.isUpdateByNationalHead == true) {
            updateFinalWPbyNH({ recordId: this.recordId, pbtvalue: this.summaryTotals.totalforebitda, moduleFinanceINR: this.summaryTotals.moduleFinanceINR }).then(result => {
                console.log('result updateFinalWPbyNH : ', result);
                if (this.isLockPrice == false) {
                    savePricingData({ recordId: this.recordId, rawJson: JSON.stringify(this.oliData[this.activeIndex]), costRows: JSON.stringify(this.costRows), inboundlog: JSON.stringify(this.filteredData), seaFreightData: JSON.stringify(this.seaFreightData), inlandTransportData: JSON.stringify(this.inlandTransportData), financialParams: JSON.stringify(this.financialParams), aopEbitda: JSON.stringify(this.segments), preEbitda: JSON.stringify(this.segmentspre), indiaPro: JSON.stringify(this.filteredDataIndiapdate), cmvPro: JSON.stringify(this.filteredDataCMVUpdate), package2040: JSON.stringify(this.rawdata), outboundlog: JSON.stringify(this.outboundlogisticattachment) })
                        .then((result) => {
                            console.log('Save pricing data by kam: ', result);
                        })
                        .catch(error => {
                            console.log('error saving by kam: ', error);
                        });
                }
                this.showSuccessToast('Updated successfully!');
                this.closeModal();
            }).catch(error => {
                console.log('error updateFinalWPbyNH : ', error);
                this.showErrorToast('Updation Failed');
            })
        }
    }
    showSuccessToast(message) {
        const event = new ShowToastEvent({
            title: 'Success',
            message: message,
            variant: 'success',
        });
        this.dispatchEvent(event);
    }

    closeModal() {
        console.log('Navigating away...');
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                actionName: 'view',
            },
        });
    }
    showErrorToast(message) {
        const event = new ShowToastEvent({
            title: 'Error',
            message: message,
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }

}