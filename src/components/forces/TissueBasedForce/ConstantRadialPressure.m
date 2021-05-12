classdef ConstantRadialPressure < AbstractTissueBasedForce
	% This adds a constant force to each NodeCell in the simulation
	% that points radially form a point.
	% force is a scalar magnitude - positive means it pushes away from
	% the centre, negative means it pushes towards the centre


	properties

		pressure
		membrane
		radius

		tooClose = false

	end

	methods


		function obj = ConstantRadialPressure(pressure, membrane, rad)

			% Pressure is the force per unit area
			% membrane is a pointer to the membrane object
			% rad is the radius of a NodeCell. In TumourInMembrane, this will be dSN/2
			obj.pressure = pressure;
			obj.membrane = membrane;
			obj.radius = rad;

		end

		function AddTissueBasedForces(obj, tissue)

			if ~obj.tooClose
				CalculateAndAddForce(obj, tissue);
			end

		end

		function CalculateAndAddForce(obj, tissue)

			nPos = reshape([obj.membrane.nodeList.position],2,[])';
			centre = mean(nPos);


			% For each node, find its distance from the centre,
			% and angle from the horizontal that it covers assuming it is
			% uncompressed. A cell further out will cover a smaller angle.
			% Then we calculate the total angle where it is not covered by another
			% cell. We use this angle and its radius to calculate the force
			% applied due to internal pressure.


			% If we get too close to the centre point, then this breaks down
			% and we start getting imagniary numbers, and the whole
			% force calculation no longer makes sense. We turn it off once
			% the cells get within a diameter of the centre.

			loc = [];

			for i = 1:length(tissue.cellList)
				c = tissue.cellList(i);
				if isa(c, 'NodeCell')
					n = c.nodeList;
					r = n.position - centre;
					rmag = norm(r);
					loc(i, :) = [i, r, rmag];

					if rmag < 2*obj.radius
						obj.tooClose = true;
						% fprintf('Internal pressure turned off\n');
						break;
					end
				end

			end

			
			if ~obj.tooClose

				loc = sortrows(loc,3);


				% We now have each node in order of its distance from the centre
				% Starting from the closest node, calculate the angle it covers
				% Subtract away any portion of the angle that already exists in the tally
				% and use this to calculate the force due to internal pressure
				% Add the remaining angle to the tally.
				% Repeat until the tally covers the whole circle, or all nodes have been done

				i = 1;

				remAngles = AngleInterval();

				while i <= length(loc) && ~remAngles.IsCircleComplete()

					nid 		= loc(i,1);
					r 			= loc(i,2:3);
					rmag 		= loc(i,4);

					if nid > 0 % If this happens we've hit a cell that isn't a NodeCell

						theta 		= asin(r(2)/rmag);
						
						% Have to convert this to a full angle since asin doesn't have the full range
						theta 		= (r(1) < 0) * sign(r(2)) * pi  + sign(r(1)) * theta;


						dtheta 		= asin(  obj.radius / (2*rmag)  ); % Don't need to convert this because its in the range for asin
						angBottom 	= theta - dtheta;
						angTop		= theta + dtheta;

						if angTop > pi
							angTop = angTop - 2* pi;
						end

						if angBottom < -pi
							angBottom = angBottom + 2*pi;
						end

						angleCovered = remAngles.GetUnvistedAngle([angBottom, angTop]);

						arcLength = rmag * angleCovered;

						force = obj.pressure * arcLength * r / rmag;

						if ~isreal(force)
							error('CRP:NotReal','Somehow the force is not real: theta %g + %g i', real(theta), imag(theta))
						end

						tissue.cellList(nid).nodeList.AddForceContribution(force);

					end

					i = i + 1;

				end

			end


		end

	end

end