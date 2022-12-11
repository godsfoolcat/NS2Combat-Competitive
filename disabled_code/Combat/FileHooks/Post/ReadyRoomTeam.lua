
function ReadyRoomTeam:GetTeamBrain()  --TODO Ideally, this should NOT late-init. Better to init, and perform conditional updates than get hit at run-time
    if self.brain == nil then
        self.brain = TeamBrain()
        self.brain:Initialize(self.teamName.."-Brain", self:GetTeamNumber())
    end

    return self.brain
end