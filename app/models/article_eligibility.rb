
class ArticleEligibility
  #There are different requirements for users who have an eligible note and users who do not depending on patron type
  def view_for(requestor)
    public_send("view_for_#{requestor.class}".downcase.to_sym)
  rescue NoMethodError
    default_view
  end

  #Any user whose Millenium patron account has a note that says book scan eligible
  def view_for_eligible
    "new"
  end

  #A faculty type patron who has not yet opted in to the scan service
  def view_for_faculty
    "required"
  end

  #A student who is either ineligible for the article scan service or who needs to enroll
  def view_for_student
    "student"
  end

  #For all others of a different patron type who are ineligible
  def default_view
    "ineligible"
  end

end

#Build classes for all the possible types of requestors
class AllEligibility
  def self.all
    [Eligible, Faculty, Student, NullEligibile]
  end
end

Eligibility = Struct.new(:requestor)

class Eligible < Eligibility
  def self.match?(requestor)
    #TO DO: STILL HAVE PLENTY OF CONDITIONALS TO DO AWAY WITH
    if not requestor.note.nil?
      #Explode the array into a string if an array, else just use the existing note if it is a string
      if requestor.note.kind_of?(Array)
        note_string = requestor.note.join(" ")
      else
        note_string = requestor.note
      end
      #Determine whether the string or the array of notes contain the specified phrase
      if note_string.include? "book scan eligible"
        return true
      else
        return false
      end
    else
      return false
    end
  end
end

class Faculty < Eligibility
  def self.match?(requestor)
    requestor.type == Patron::Type::FACULTY
  end
end

class Student < Eligibility
  def self.match?(requestor)
    requestor.type == Patron::Type::GRAD_STUDENT or requestor.type == Patron::Type::UNDERGRAD
  end
end

class NullEligibile < Eligibility
  def self.match?(requestor)
    true
  end
end

#The factory matches what comes in as a param to the requestor class that is needed to render the correct view
class EligibilityFactory
  def self.build(requestor)
    AllEligibility.all.detect { |s| s.match?(requestor) }.new(requestor)
  end
end
