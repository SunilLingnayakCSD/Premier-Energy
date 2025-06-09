import { LightningElement, wire, api, track } from 'lwc';
import getRawMaterialData from '@salesforce/apex/RawMaterialLogger.RawMaterial';
import userId from '@salesforce/user/Id';
import getUserProfileName from '@salesforce/apex/RawMaterialLogger.getUserProfileName';
import getAdminInputs from '@salesforce/apex/RawMaterialLogger.getAdminInputs';
import createVariables from '@salesforce/apex/RawMaterialLogger.createVariables';
import checkVariables from '@salesforce/apex/RawMaterialLogger.checkVariables';
import updatefinals from '@salesforce/apex/RawMaterialLogger.updateFinalWP';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
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

    countryOptions = [
        { label: 'China', value: 'China' },
        { label: 'Malaysia', value: 'Malaysia' },
        { label: 'Vietnam', value: 'Vietnam' }
    ];

    pricingOptions = [
        { label: 'Average Price', value: 'Average Price' },
        { label: 'Low Price', value: 'Low Price' }
    ];

    connectedCallback() {
        getUserProfileName({ userId: this.currentUserId })
            .then(profileName => {
                console.log('profileName : ', profileName);
                if (profileName == 'Key Accounts National Head') {
                    this.isEditable = true;
                }
                if (profileName == 'Key Accounts Region Head') {
                    this.seeFinalOnly = true;
                    console.log('seeFinalOnly : ', this.seeFinalOnly);
                }
            })
            .catch(error => {
                console.error('Error fetching profile:', error);
            });
    }
    get isDisabled() {
        return !this.isEditable;
    }

    get currentProduct() {
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
            this.handleRawMaterialsAsync(data);
        } else {
            console.error('Wire error:', error);
        }
    }
    async handleRawMaterialsAsync(data) {
        try {
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
        console.log('this.currentProduct.oliId -->: ', this.currentProduct.oliId);
        console.log('this.currentProduct.totalInrWp -->: ', this.currentProduct.totalInrWp);
        const totalvalue = parseFloat(this.currentProduct.totalInrWp) || 0;
        console.log('Admin data--> : ', data);
        console.log('cbitc--> : ', data.cbitc);
        console.log('totalInrWp--> : ', totalvalue);
        console.log('data.warrantyInsurance--> : ', data.warrantyInsurance);
        console.log('data.rfidCostINR--> : ', data.rfidCostINR);
        console.log('data.moduleOverheadINR--> : ', data.moduleOverheadINR);
        console.log('addvalues--> : ', parseFloat(totalvalue + data.rfidCostINR + data.moduleOverheadINR));
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
        var bGradeModuleLossINR = ((totalvalue + data.rfidCostINR + data.moduleOverheadINR + data.cellBOMINR + data.cellOverheadINR + data.cellFinanceINR + moduleWarrantyInsuranceCostINR) * (data.bgrademodulediscount / 100) * (data.bgrademoduleyield / 100));
        var bGradeModuleLossCent = ((bGradeModuleLossINR * 100) / data.rbi);
        bGradeModuleLossINR = Number(bGradeModuleLossINR.toFixed(2));
        bGradeModuleLossCent = bGradeModuleLossCent.toFixed(2);
        const abgCostINR = Number((
            (parseFloat(data.abgvalue) || 0) *
            (parseFloat(data.abgpbgcost / 100) || 0) /
            365 *
            (parseFloat(data.abgvalidity) || 0) /
            (parseFloat(data.projectcapacity) || 1) /
            1000000
        ).toFixed(2));
        const abgCostCent = ((abgCostINR * 100) / data.rbi).toFixed(2);
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

        const pbgCostCent = ((pbgCostINR * 100) / data.rbi).toFixed(2);
        console.log('data.insurancepremiumcost--> : ', data.insurancepremiumcost);
        var transitinsurancecostINR = parseFloat(totalvalue + data.rfidCostINR + data.moduleOverheadINR + data.moduleFinanceINR + data.cellBOMINR + data.cellOverheadINR + data.cellFinanceINR + moduleWarrantyInsuranceCostINR + bGradeModuleLossINR + abgCostINR + pbgCostINR + data.outboundlogisticsINR + data.exportfreightchargesINR) * (data.insurancepremiumcost / 100);
        var transitinsurancecostCent = (transitinsurancecostINR * 100 / data.rbi);
        transitinsurancecostINR = Number(transitinsurancecostINR.toFixed(2));
        console.log('transitinsurancecostINR--> : ', transitinsurancecostINR);
        transitinsurancecostCent = transitinsurancecostCent.toFixed(2);
        console.log('data.paymentterm--> : ', data.paymentterm);
        console.log('data.lcinterestcost--> : ', data.lcinterestcost);
        console.log('data.lcusanceperiod--> : ', data.lcusanceperiod);
        const sumforlcinterest = parseFloat(totalvalue + data.rfidCostINR + data.moduleOverheadINR + data.moduleFinanceINR + data.cellBOMINR + data.cellOverheadINR + data.cellFinanceINR + moduleWarrantyInsuranceCostINR + bGradeModuleLossINR + abgCostINR + pbgCostINR + data.outboundlogisticsINR + data.exportfreightchargesINR);
        let lcinterestcostINR = 0.00;
        let lcinterestcostCent = 0.00;
        if (data.paymenttrembalance == 'LC') {
            lcinterestcostINR = (
                (parseFloat(sumforlcinterest)) *
                (parseFloat(1 - (data.paymentterm / 100))) *
                parseFloat(data.lcinterestcost / 100) / 365 *
                parseFloat(data.lcusanceperiod)
            );
            lcinterestcostINR = Number(lcinterestcostINR.toFixed(2));
            lcinterestcostCent = (lcinterestcostINR * 100 / data.rbi).toFixed(2);
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
        this.costRows = [
            { label: 'RFID reader cost', col2: data.rfidCostINR, col3: data.rfidCostCents },
            { label: 'Module Overhead cost (cents/Wp)', col2: data.moduleOverheadINR, col3: data.moduleOverheadCents },
            { label: 'Module Finance Cost(Cents/Wp)', col2: data.moduleFinanceINR, col3: data.moduleFinanceCents },
            { label: 'Cell BOM Cost (Cents/Wp)', col2: data.cellBOMINR, col3: data.cellBOMCents },
            { label: 'Cell - Overhead Cost (Cents/Wp)', col2: data.cellOverheadINR, col3: data.cellOverheadCents },
            { label: 'Cell- Finance Cost(Cents/Wp)', col2: data.cellFinanceINR, col3: data.cellFinanceCents },
            { label: 'Module Warranty insurance Cost', col2: moduleWarrantyInsuranceCostINR, col3: moduleWarrantyInsuranceCostCent },
            { label: 'B-Grade Module Loss', col2: bGradeModuleLossINR, col3: bGradeModuleLossCent },
            { label: 'ABG Cost', col2: abgCostINR, col3: abgCostCent },
            { label: 'PBG Cost', col2: pbgCostINR, col3: pbgCostCent },
            { label: 'outbound logistics', col2: data.outboundlogisticsINR, col3: data.outboundlogisticsCent },
            { label: 'Export Freight Charges', col2: data.exportfreightchargesINR, col3: data.exportfreightchargesCent },
            { label: 'Transit Insurance Cost', col2: transitinsurancecostINR, col3: transitinsurancecostCent },
            { label: 'LC Interest Cost', col2: lcinterestcostINR, col3: lcinterestcostCent },
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
    }

    handlePricingChange(event) {
        this.pricingType = event.detail.value;
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
        return value?.toFixed(2) || '0.00';
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
        console.log('ebita--> : ', this.summaryTotals.totalforebitda);
        console.log('moduleFinanceINR--> : ', this.summaryTotals.moduleFinanceINR);
        console.log('OUTPUT : ',);
        updatefinals({ recordId: this.recordId, finalprice: this.summaryTotals.finalPrice, pbtvalue: this.summaryTotals.totalforebitda, moduleFinanceINR: this.summaryTotals.moduleFinanceINR }).then(result => {
            console.log('result : ', result);
            this.showSuccessToast('Updated successfully!');
            this.closeModal();
        }).catch(error => {
            console.log('error : ', error);
             this.showErrorToast('Updation Failed');
        })
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