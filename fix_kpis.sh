#!/bin/bash

for file in /home/vasco/develop/skalway/apps/phrx/app/lib/modules/dashboard/domain/mappers/*_kpis.dart; do
    sed -i 's|import '"'"'../../../../shared/widgets/cards/enterprise_kpi_grid.dart'"'"';|import '"'"'../../../../shared/widgets/dashboard/enterprise_kpi_card.dart'"'"';|g' "$file"
    sed -i 's/List<EnterpriseStatCard>/List<EnterpriseKpiCard>/g' "$file"
    sed -i 's/dashboardKpiCard(/EnterpriseKpiCard(/g' "$file"
    sed -i 's/accent: StatCardAccent.positive,/trend: EnterpriseKpiTrend.positive,/g' "$file"
    sed -i 's/accent: StatCardAccent.negative,/trend: EnterpriseKpiTrend.negative,/g' "$file"
    sed -i 's/accent: StatCardAccent.danger,/trend: EnterpriseKpiTrend.negative,/g' "$file"
    sed -i 's/accent: StatCardAccent.warning,/trend: EnterpriseKpiTrend.negative,/g' "$file"
    sed -i 's/accent: StatCardAccent.neutral,/trend: EnterpriseKpiTrend.neutral,/g' "$file"
    sed -i 's/accent: StatCardAccent.info,/trend: EnterpriseKpiTrend.neutral,/g' "$file"
done
