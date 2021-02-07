#property copyright "2021 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#define SingletonContructor(T) private: T() {}; public: static T * getInstance() {if (!instance) instance = new T(); return (T *) instance;}

/**
 * This class represents a singleton object.
 */
template <typename T> class Singleton {
    protected:
        Singleton() {};
        static T * instance;

    public:
        /**
         * All the implementations need to
         * be manually deleted in DeInit.
         */
        static void deleteInstance() {
            if (instance) {
                delete instance;
                instance = NULL;
            }
        }
};

template <typename T> T * Singleton::instance = NULL;

/**
 * Example of implementation of a singleton class.
 */
class Ciao : public Singleton<Ciao> {
    SingletonContructor(Ciao);

    private:
        int count_;

    public:
        void printCiao() {
            Print("Ciao");
            count_++;
        }

        int getCount () {
            return count_;
        }
};
