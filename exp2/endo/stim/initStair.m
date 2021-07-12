% Purpose:  Initialize up-down staircase with pre-defined parameters

function stair = initStair(subj,p,session)

if session
   stair = [];
else
   % check if subject has already had an initialized staircase
   threshDir = ['../data/',subj,'/threshold/'];
   if exist([threshDir,'stair.mat'],'file')
      setupStair = 0;
      load([threshDir,'stair.mat'],'stair');
   else
      setupStair = 1;
   end

   if setupStair
      % initialize the interleaved staircases for each start level
      allStartLevels = p.stairParams.startLevel;
      for s = 1:length(p.taskParams.sfs)
         for e = 1:length(p.taskParams.ecc)
            for lev = 1:length(allStartLevels)
               p.stairParams.startLevel = allStartLevels(lev);
               stair(e,s,lev) = nDown1Up(p.stairParams);
            end
         end
      end
   end
end

