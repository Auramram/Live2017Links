--インフェルノイド・シャイターン
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	--special summon condition
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_SPSUMMON_CONDITION)
	c:RegisterEffect(e1)
	--special summon
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_SPSUMMON_PROC)
	e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e2:SetRange(LOCATION_HAND)
	e2:SetCondition(s.spcon)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
	--todeck
	local e3=Effect.CreateEffect(c)
	e3:SetCategory(CATEGORY_TODECK)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_MZONE)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e3:SetCountLimit(1)
	e3:SetTarget(s.tdtg)
	e3:SetOperation(s.tdop)
	c:RegisterEffect(e3)
	--remove
	local e4=Effect.CreateEffect(c)
	e4:SetCategory(CATEGORY_REMOVE)
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_FREE_CHAIN)
	e4:SetRange(LOCATION_MZONE)
	e4:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e4:SetCountLimit(1)
	e4:SetCondition(s.rmcon)
	e4:SetCost(s.rmcost)
	e4:SetTarget(s.rmtg)
	e4:SetOperation(s.rmop)
	c:RegisterEffect(e4)
end
function s.spfilter(c)
	return c:IsSetCard(0xbb) and c:IsType(TYPE_MONSTER) and c:IsAbleToRemoveAsCost() 
		and (c:IsLocation(LOCATION_HAND) or aux.SpElimFilter(c,true,true))
end
function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	local sum=0
	for i=0,6 do
		local tc=Duel.GetFieldCard(tp,LOCATION_MZONE,i)
		if tc and tc:IsFaceup() and tc:IsType(TYPE_EFFECT) then
			if tc:IsType(TYPE_XYZ) then sum=sum+tc:GetRank()
			else sum=sum+tc:GetLevel() end
		end
	end
	if sum>8 then return false end
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
	if ft<0 then return false end
	if c:IsHasEffect(34822850) then
		if ft>0 then
			return Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_MZONE+LOCATION_GRAVE+LOCATION_HAND,0,1,c)
		else
			return Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_MZONE,0,1,nil)
		end
	else
		if Duel.IsPlayerAffectedByEffect(tp,69832741) then
			return Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_MZONE+LOCATION_HAND,0,1,c)
		else
			return ft>0 and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE+LOCATION_HAND,0,1,c)
		end
	end
end
function s.spop(e,tp,eg,ep,ev,re,r,rp,c)
	local g=nil
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	if c:IsHasEffect(34822850) then
		if Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
			g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_MZONE+LOCATION_GRAVE+LOCATION_HAND,0,1,1,c)
		else
			g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_MZONE,0,1,1,nil)
		end
	else
		if Duel.IsPlayerAffectedByEffect(tp,69832741) then
			if ft>0 then
				g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_MZONE+LOCATION_HAND,0,1,1,c)
			else
				g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_MZONE,0,1,1,c)
			end
		else
			g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_GRAVE+LOCATION_HAND,0,1,1,c)
		end
	end
	Duel.Remove(g,POS_FACEUP,REASON_COST)
end
function s.tdfilter(c)
	return c:IsFacedown() and c:IsAbleToDeck()
end
function s.tdtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsOnField() and s.tdfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.tdfilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g=Duel.SelectTarget(tp,s.tdfilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,g,1,0,0)
	Duel.SetChainLimit(s.limit(g:GetFirst()))
end
function s.tdop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.SendtoDeck(tc,nil,2,REASON_EFFECT)
	end
end
function s.limit(c)
	return	function (e,lp,tp)
				return e:GetHandler()~=c
			end
end
function s.rmcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()~=tp
end
function s.rmfilter(c,e)
	return c:IsAbleToRemove() and aux.SpElimFilter(c) and (not e or c:IsCanBeEffectTarget(e))
end
function s.rmcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local dg=Duel.GetMatchingGroup(s.rmfilter,tp,0,LOCATION_MZONE+LOCATION_GRAVE,nil,e)
	if chk==0 then return Duel.CheckReleaseGroupCost(tp,nil,1,false,aux.ReleaseCheckTarget,nil,dg) end
	local g=Duel.SelectReleaseGroupCost(tp,nil,1,1,false,aux.ReleaseCheckTarget,nil,dg)
	Duel.Release(g,REASON_COST)
end
function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE+LOCATION_GRAVE) and chkc:IsControler(1-tp) and s.rmfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.rmfilter,tp,0,LOCATION_MZONE+LOCATION_GRAVE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectTarget(tp,s.rmfilter,tp,0,LOCATION_MZONE+LOCATION_GRAVE,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,g,1,0,0)
end
function s.rmop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.Remove(tc,POS_FACEUP,REASON_EFFECT)
	end
end
