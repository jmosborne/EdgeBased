classdef DynamicCryptStatistics < Analysis

	% Pass in a visualiser object with all the SpatialData
	% and use it to produce an analysis of the cell movement
	properties

		analysisName = 'DynamicCryptStatistics';

		parameterSet = []

		simulationRuns = 1
		slurmTimeNeeded = 24
		simulationDriverName = 'DynamicCrypt'
		simulationInputCount = 7

		visualiser

	end

	methods

		function obj = DynamicCryptStatistics(v)

			obj.seedIsInParameterSet = false; % The seed not given in MakeParameterSet, it is set in properties
			obj.seedHandledByScript = false; % The seed will be in the parameter file, not the job script
  			obj.usingHPC = false;

  			obj.visualiser = v;
		end

		function MakeParameterSet(obj)

			obj.parameterSet = [];

		end

	

		function AssembleData(obj)

			v = obj.visualiser;

			nodes = v.nodes;
			cells = v.cells;

			x = nan(size(cells));
			y = nan(size(cells));

			t = v.timeSteps;

			dt = t(2) - t(1);

			% We want to extract the centre of each cell over time so we
			% can follow its progress up and out of the crypt
			for i = 1:length(t)
				[~,J] = size(cells);
				j = 1;
				while j <= J && ~isempty(cells{i,j})
					% At each time step, capture the position of the given cell
					c = cells{i,j};
					ids = c(1:end-1);
					colour = c(end);
					nodeCoords = squeeze(nodes(ids,i,:));
					centre = mean(nodeCoords);

					x(i,j) = centre(1);
					y(i,j) = centre(2);

					j = j + 1;

				end

			end

			% Given the y positions, need to get the velocity in the given timestep
			% Need to watch out because when a cell divides, one of the daughter cells
			% keeps the id of the parent cell

			speed = sqrt(  (x(2:end,:) - x(1:end-1,:)).^2  +  (y(2:end,:) - y(1:end-1,:)).^2  ) / dt;



			obj.result = {t, x, y, speed};

		end

		function PlotData(obj, varargin)

			t = obj.result{1};
			x = obj.result{2};
			y = obj.result{3};
			speed = obj.result{4};



			h = figure;

			plot3(t,x,y);
			SavePlot(obj, h, sprintf('Migration'));

			h = figure;
			ts = speed(:);
			ty = y(2:end,:);
			ty = ty(:);

			ty(ts > 1) = [];
			ts(ts > 1) = [];
			scatter(ty, ts)
			SavePlot(obj, h, sprintf('Speed'));


		end

	end

end