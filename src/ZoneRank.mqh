#ifndef GSM_SC01_ZONE_RANK
#define GSM_SC01_ZONE_RANK

bool ZoneRankBetter(const bool nearestOnly,const bool hasBest,
                    const double distance,const double bestDistance,
                    const double score,const double bestScore)
{
   if(nearestOnly) return !hasBest || distance<bestDistance;
   return score>bestScore;
}

#endif
